//
//  PlayerManager.swift
//  iPlayMusic
//
//  Created by Shiv on 02/09/26.
//

import SwiftUI
import Combine
import VLCKit
import MediaPlayer

// MARK: - Player Events
enum MediaPlayerEvent {
    case currentMedia(VLCMedia?, SongModel?)
    case stoppedPlayback(VLCMediaListPlayer)
    case finishedPlayback(VLCMediaListPlayer)
}

final class PlayerManager: NSObject, ObservableObject {
    static let shared: PlayerManager = .init()
    
    private var mediaListPlayer: VLCMediaListPlayer?
    var mediaList: VLCMediaList = VLCMediaList()
    
    @AppStorage("isShuffle") var isShuffle: Bool = false
    @AppStorage("isOnEqualizer") var isOnEqualizer: Bool = false
    @AppStorage("repeatMode") var repeatMode: VLCRepeatMode = .doNotRepeat {
        didSet {
            mediaListPlayer?.repeatMode = repeatMode
        }
    }
    @AppStorage("playerVolume") var volume: Double = 1.0 {
        didSet {
            applyVolume()
        }
    }
    @AppStorage("decoderType") var decoderType: DecoderType = .hwDecoder
    
    // MARK: - Sleep Timer Properties
    @AppStorage("sleepTimerTargetDate") private var sleepTimerTargetDate: TimeInterval = 0
    @Published var remainingTime: TimeInterval = 30
    private var sleepTimer: Timer?
    
    @Published var isMute: Bool = false
    @Published var playbackRate: Float = 1.0 {
        didSet {
            mediaListPlayer?.mediaPlayer.rate = playbackRate
        }
    }
    @Published var currentDuration: VLCTime = VLCTime()
    @Published var totalDuration: VLCTime = VLCTime()
    @Published var position: Float = 0
    @Published var power: Double = 0
    @Published var state: VLCMediaPlayerState = .stopped
    @Published private(set) var miliseconds: Int32 = 0
    @Published var eqBands: VLCAudioEqualizer = VLCAudioEqualizer()
    @Published var preset: VLCAudioEqualizer.Preset? = VLCAudioEqualizer.presets.first
    @Published var currentVlcMedia: VLCMedia?
    @Published var currentSong: SongModel?
    @Published var currentPlaybackSource: PlaybackSource = .songs
    @Published var queueSongsList: [SongModel] = []
    
    let event = PassthroughSubject<MediaPlayerEvent, Never>()
    
    private var artworkCache: [String: MPMediaItemArtwork] = [:]
    private var currentArtwork: MPMediaItemArtwork?
    
    private override init() {
        super.init()
        checkAndResumeTimer()
        setupRemoteCommandCenter()
        restoreQueue()
    }
    
    private func restoreQueue() {
        let restoredSongs = QueueRealmViewModel.shared.loadQueue()
        guard !restoredSongs.isEmpty else { return }
        queueSongsList = restoredSongs
    }
    
    private func setupRemoteCommandCenter() {
            let commandCenter = MPRemoteCommandCenter.shared()
            
            commandCenter.playCommand.addTarget { [weak self] _ in
                self?.mediaListPlayer?.play()
                return .success
            }
            
            commandCenter.pauseCommand.addTarget { [weak self] _ in
                self?.mediaListPlayer?.pause()
                return .success
            }
            
            commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
                self?.playPause()
                return .success
            }
            
            commandCenter.nextTrackCommand.addTarget { [weak self] _ in
                self?.nextPlay()
                return .success
            }
            
            commandCenter.previousTrackCommand.addTarget { [weak self] _ in
                self?.previousPlay()
                return .success
            }
            
            commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
                guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                self.mediaListPlayer?.mediaPlayer.time = VLCTime(int: Int32(event.positionTime * 1000))
                return .success
            }
        }
    
    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentSong?.name ?? "Unknown"
        info[MPMediaItemPropertyArtist] = currentSong?.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(mediaListPlayer?.mediaPlayer.time.intValue ?? 0) / 1000.0
        info[MPMediaItemPropertyPlaybackDuration] = Double(totalDuration.intValue) / 1000.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = state == .playing ? Double(playbackRate) : 0.0
        if let artwork = currentArtwork {
            info[MPMediaItemPropertyArtwork] = artwork      // 👈 add ye
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func loadArtwork(for song: SongModel?) {
        guard let song = song, let urlString = song.thumbnailURL, let url = URL(string: urlString) else {
            currentArtwork = nil
            updateNowPlayingInfo()
            return
        }
        
        // Cache hit — dubara download nahi
        if let cached = artworkCache[song.id] {
            currentArtwork = cached
            updateNowPlayingInfo()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
#if os(macOS)
            guard let self, let data, let image = NSImage(data: data) else { return }
#else
            guard let self, let data, let image = UIImage(data: data) else { return }
#endif
            
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            
            DispatchQueue.main.async {
                self.artworkCache[song.id] = artwork
                // Race-condition guard: jab tak download hua, tab tak song change na ho gaya ho
                if self.currentSong?.id == song.id {
                    self.currentArtwork = artwork
                    self.updateNowPlayingInfo()
                }
            }
        }.resume()
    }
    
    func setupPlay(songs: [SongModel], playIndex: Int, source: PlaybackSource = .songs) {
        Task { @MainActor in
            if mediaListPlayer == nil {
                mediaListPlayer = VLCMediaListPlayer()
            }
            
            var validPairs: [(song: SongModel, media: VLCMedia)] = []
            for song in songs {
                guard let audioQualityURL = song.downloadUrl?.first(where: { $0.quality == .kbps320 })?.url, let url = URL(string: audioQualityURL) else { continue }
                guard let newMedia = VLCMedia(url: url) else { continue }
                newMedia.delegate = self
                newMedia.addOptions(decoderType.codecOptions)
                validPairs.append((song, newMedia))
            }
            
            guard !validPairs.isEmpty else { return }
            
            queueSongsList = validPairs.map { $0.song }
            currentPlaybackSource = source
            let medias = validPairs.map { $0.media }
            QueueRealmViewModel.shared.saveQueue(queueSongsList)
            let safePlayIndex = min(max(playIndex, 0), medias.count - 1)
            
            mediaList = VLCMediaList(array: medias)
            
            let vlcLogger = VLCConsoleLogger()
            vlcLogger.level = .debug
            vlcLogger.formatter.contextFlags = .levelContextAll
            mediaListPlayer?.mediaPlayer.libraryInstance.loggers = [vlcLogger]
            
            mediaListPlayer?.delegate = self
            mediaListPlayer?.mediaPlayer.delegate = self
            mediaListPlayer?.mediaList = self.mediaList
            
            guard let playMedia = self.mediaList.media(at: UInt(safePlayIndex)) else { return }
            currentVlcMedia = playMedia
            currentSong = queueSongsList[safePlayIndex]
            loadArtwork(for: currentSong)
            playbackRate = mediaListPlayer?.mediaPlayer.rate ?? 1.0
            
            totalDuration = playMedia.length
            mediaListPlayer?.repeatMode = repeatMode
            mediaListPlayer?.play(playMedia)
            applyVolume()
            reapplyEqualizerIfNeeded()
            event.send(.currentMedia(currentVlcMedia, currentSong))
            updateNowPlayingInfo()
        }
    }
    
    func playFromPlaylist(index: Int) {
        guard let media = self.mediaList.media(at: UInt(index)) else { return }
        currentVlcMedia = media
        currentSong = queueSongsList.filter({ $0.downloadUrl?.first(where: { $0.quality == .kbps320 })?.url == currentVlcMedia?.url?.absoluteString }).first
        loadArtwork(for: currentSong)
        guard let playing = currentVlcMedia else { return }
        mediaListPlayer?.play(playing)
        applyVolume()
        reapplyEqualizerIfNeeded()
        event.send(.currentMedia(currentVlcMedia, currentSong))
        updateNowPlayingInfo()
    }
    
    func playQueueItem(at index: Int) {
        guard index < queueSongsList.count else { return }
        if mediaList.count == queueSongsList.count {
            playFromPlaylist(index: index)
        } else {
            setupPlay(songs: queueSongsList, playIndex: index, source: currentPlaybackSource)
        }
    }
    
    /// Queue me drag-and-drop se reorder karta hai — `queueSongsList`,
    /// underlying `mediaList` (VLC), aur persisted local queue (Realm)
    /// teeno ko sync rakhta hai.
    func moveSong(id: String, to targetIndex: Int) {
        guard let fromIndex = queueSongsList.firstIndex(where: { $0.id == id }) else { return }
        guard fromIndex != targetIndex else { return }
        
        // MARK: 1. queueSongsList reorder (UI list)
        let song = queueSongsList.remove(at: fromIndex)
        let clampedTarget = min(max(targetIndex, 0), queueSongsList.count)
        queueSongsList.insert(song, at: clampedTarget)
        
        // MARK: 2. VLC mediaList reorder — same index se, kyunki queueSongsList
        // aur mediaList hamesha parallel/same-order maintain karte hain
        if fromIndex < mediaList.count {
            mediaList.lock()
            if let media = mediaList.media(at: UInt(fromIndex)) {
                mediaList.removeMedia(at: UInt(fromIndex))
                mediaList.insert(media, at: UInt(clampedTarget))
            }
            mediaList.unlock()
        }
        
        // MARK: 3. Local persisted queue bhi naye order se save karo
        QueueRealmViewModel.shared.saveQueue(queueSongsList)
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queueSongsList.count else { return }
        let song = queueSongsList[index]
        
        queueSongsList.remove(at: index)
        
        // VLC ka actual live mediaList operate karo — self.mediaList ki jagah
        if let liveMediaList = mediaListPlayer?.mediaList, index < liveMediaList.count {
            liveMediaList.lock()
            liveMediaList.removeMedia(at: UInt(index))
            liveMediaList.unlock()
        }
        
        QueueRealmViewModel.shared.removeSong(songId: song.id)
    }
    
    func clearQueue() {
        queueSongsList.removeAll()
        mediaList = VLCMediaList()
        QueueRealmViewModel.shared.clearQueue()
    }
    
    
    
    func nextPlay() {
        if !isShuffle {
            guard let currentMedia = self.currentVlcMedia else { return }
            let currentIndex = mediaList.index(of: currentMedia)
            
            switch repeatMode {
            case .repeatAllItems:
                let nextIndex = (Int(currentIndex) + 1) % mediaList.count
                guard let media = mediaList.media(at: UInt(nextIndex)) else { return }
                currentVlcMedia = media
            case .repeatCurrentItem:
                guard let media = mediaList.media(at: UInt(currentIndex)) else { return }
                currentVlcMedia = media
            case .doNotRepeat:
                let nextIndex = (Int(currentIndex) + 1) % mediaList.count
                guard let media = mediaList.media(at: UInt(nextIndex)) else { return }
                currentVlcMedia = media
            default:
                break
            }
        } else {
            if let randomMedia = mediaList.media(at: UInt.random(in: 0..<UInt(mediaList.count))) {
                currentVlcMedia = randomMedia
            }
        }
        currentSong = queueSongsList.filter({ $0.downloadUrl?.first(where: { $0.quality == .kbps320 })?.url == currentVlcMedia?.url?.absoluteString }).first
        loadArtwork(for: currentSong)
        guard let playing = currentVlcMedia else { return }
        mediaListPlayer?.play(playing)
        reapplyEqualizerIfNeeded()
        event.send(.currentMedia(currentVlcMedia, currentSong))
        updateNowPlayingInfo()
    }
    
    func previousPlay() {
        if isShuffle {
            guard let currentMedia = mediaListPlayer?.mediaPlayer.media else { return }
            let currentIndex = mediaList.index(of: currentMedia)
            
            switch repeatMode {
            case .repeatAllItems:
                let previousIndex = (Int(currentIndex) - 1 + mediaList.count) % mediaList.count
                guard let media = mediaList.media(at: UInt(previousIndex)) else { return }
                currentVlcMedia = media
            case .repeatCurrentItem:
                guard let media = mediaList.media(at: UInt(currentIndex)) else { return }
                currentVlcMedia = media
            case .doNotRepeat:
                let previousIndex = (Int(currentIndex) - 1 + mediaList.count) % mediaList.count
                guard let media = mediaList.media(at: UInt(previousIndex)) else { return }
                currentVlcMedia = media
            default:
                break
            }
        } else {
            if let randomMedia = mediaList.media(at: UInt.random(in: 0..<UInt(mediaList.count))) {
                currentVlcMedia = randomMedia
            }
        }
        currentSong = queueSongsList.filter({ $0.downloadUrl?.first(where: { $0.quality == .kbps320 })?.url == currentVlcMedia?.url?.absoluteString }).first
        loadArtwork(for: currentSong)
        guard let playing = currentVlcMedia else { return }
        mediaListPlayer?.play(playing)
        event.send(.currentMedia(currentVlcMedia, currentSong))
        updateNowPlayingInfo()
    }
    
    /// VLC audio object par current volume value push karta hai (0...1 -> 0...100)
    private func applyVolume() {
        guard let audio = mediaListPlayer?.mediaPlayer.audio else { return }
        let clamped = max(0.0, min(volume, 1.0))
        audio.volume = Int32(clamped * 100)
    }
    
    func setVolume(_ value: Float, isTracking: Bool) {
        volume = Double(value)
    }
    
    func setDecoderType(_ type: DecoderType) {
        guard decoderType != type else { return }
        decoderType = type
        reloadCurrentMediaWithNewDecoder()
    }

    /// Current playing media ko naye decoder options ke saath reload karta hai,
    /// same position se resume karta hai (seamless switch)
    private func reloadCurrentMediaWithNewDecoder() {
        guard let oldMedia = currentVlcMedia, let url = oldMedia.url else { return }
        
        let resumeTime = mediaListPlayer?.mediaPlayer.time ?? VLCTime(int: 0)
        let wasPlaying = (state == .playing)
        let oldIndex = mediaList.index(of: oldMedia)
        
        guard let newMedia = VLCMedia(url: url) else { return }
        newMedia.addOptions(decoderType.codecOptions)
        
        // mediaList me purane media ki jagah naya rakho (queue order maintain rahega)
        if oldIndex != NSNotFound {
            mediaList.lock()
            mediaList.removeMedia(at: UInt(oldIndex))
            mediaList.insert(newMedia, at: UInt(oldIndex))
            mediaList.unlock()
        }
        
        currentVlcMedia = newMedia
        mediaListPlayer?.play(newMedia)
        mediaListPlayer?.mediaPlayer.time = resumeTime
        
        if !wasPlaying {
            mediaListPlayer?.pause()
        }
        
        reapplyEqualizerIfNeeded()  // equalizer ON hai to usko bhi reapply karo
        event.send(.currentMedia(currentVlcMedia, currentSong))
        updateNowPlayingInfo()
    }
    
    func setStereoMode(_ mode: VLCMediaPlayer.AudioStereoMode) {
//        stereoModeRaw = mode.rawValue
        mediaListPlayer?.mediaPlayer.audioStereoMode = mode
    }
    
    // MARK: - Equalizer Control
    /// Equalizer ko on/off karta hai. Toggle se call hoga.
    func setEqualizerEnabled(_ enabled: Bool) {
        if enabled {
            // Player par equalizer instance attach karo (ek hi baar)
            mediaListPlayer?.mediaPlayer.equalizer = eqBands
            applyStoredEqualizerValues()
        } else {
            mediaListPlayer?.mediaPlayer.equalizer = nil
        }
    }

    /// Currently attached equalizer par saved bands/preAmp values push karta hai
    private func applyStoredEqualizerValues() {
        guard let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.preAmplification = eqBands.preAmplification
        eqBands.bands.enumerated().forEach { index, band in
            liveEq.bands[index].amplification = band.amplification
        }
    }

    /// Naya media play hone ke baad call karo — agar equalizer ON hai to reattach + reapply
    private func reapplyEqualizerIfNeeded() {
        guard isOnEqualizer else { return }
        mediaListPlayer?.mediaPlayer.equalizer = eqBands
        applyStoredEqualizerValues()
    }

    /// Slider drag karte waqt REAL-TIME call hoga (isTracking check ki zaroorat nahi)
    func updatePreAmplification(_ value: Float) {
        eqBands.preAmplification = value
        guard isOnEqualizer, let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.preAmplification = value
    }

    /// Band slider drag karte waqt REAL-TIME call hoga
    func updateBand(index: Int, amplification: Float) {
        eqBands.bands[index].amplification = amplification
        guard isOnEqualizer, let liveEq = mediaListPlayer?.mediaPlayer.equalizer else { return }
        liveEq.bands[index].amplification = amplification
    }
    
    func applyEqualizerEffect(eq: VLCAudioEqualizer, preset: VLCAudioEqualizer.Preset?) {
        guard isOnEqualizer else {
            // OFF hone par equalizer hatao
            mediaListPlayer?.mediaPlayer.equalizer = nil
            return
        }
        
        // ✅ Pehle assign karo
        mediaListPlayer?.mediaPlayer.equalizer = eq
        
        // ✅ Assign ke BAAD directly player ke equalizer par set karo
        // eq copy par nahi — player ke actual equalizer par
        mediaListPlayer?.mediaPlayer.equalizer?.preAmplification = eq.preAmplification
        
        eq.bands.enumerated().forEach { index, band in
            mediaListPlayer?.mediaPlayer.equalizer?.bands[index].amplification = band.amplification
        }
    }
    
    func playPause() {
        if mediaListPlayer?.mediaPlayer.isPlaying ?? false {
            mediaListPlayer?.pause()
        } else {
            mediaListPlayer?.play()
        }
    }
    
    func isMuted() {
        mediaListPlayer?.mediaPlayer.audio?.isMuted.toggle()
        isMute.toggle()
    }
    
    func jumpBackward(sec: Double) {
        mediaListPlayer?.mediaPlayer.jumpBackward(sec)
    }
    
    func jumpForward(sec: Double) {
        mediaListPlayer?.mediaPlayer.jumpForward(sec)
    }
    
    func seek(to position: Float, isTracking: Bool) {
        mediaListPlayer?.mediaPlayer.position = Double(position)
    }
    
    func stop() {
        mediaListPlayer?.stop()
    }
    
    func clearPlayer() {
        mediaListPlayer = nil
        mediaList = .init()
        currentVlcMedia = .init()
        currentSong = nil
        currentPlaybackSource = .songs
        queueSongsList.removeAll()
    }
    
    // Sleep Timer Methods
    func startSleepTimer(minutes: Double) {
        let targetDate = Date().addingTimeInterval(minutes * 60)
        sleepTimerTargetDate = targetDate.timeIntervalSince1970
        setupTimer(targetDate: targetDate)
    }
    
    private func setupTimer(targetDate: Date) {
        sleepTimer?.invalidate()
        
        sleepTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let timeLeft = targetDate.timeIntervalSinceNow
            
            if timeLeft <= 0 {
                self.stopPlaybackByTimer()
            } else {
                DispatchQueue.main.async {
                    self.remainingTime = timeLeft
                }
            }
        }
    }
    
    private func stopPlaybackByTimer() {
        print("Sleep Timer Triggered: Stopping Player")
        self.stop()
        cancelSleepTimer()
    }
    
    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        remainingTime = 0
        sleepTimerTargetDate = 0
    }
    
    func checkAndResumeTimer() {
        let savedDate = Date(timeIntervalSince1970: sleepTimerTargetDate)
        if savedDate > Date() {
            setupTimer(targetDate: savedDate)
        } else {
            cancelSleepTimer()
        }
    }
}

// MARK: - VLCMediaListPlayerDelegate Bridge
extension PlayerManager: VLCMediaListPlayerDelegate {
    func mediaListPlayer(_ player: VLCMediaListPlayer, nextMedia media: VLCMedia) {
        DispatchQueue.main.async {
            self.currentVlcMedia = media
            self.currentSong = self.queueSongsList.filter({ $0.downloadUrl?.first(where: { $0.quality == .kbps320 })?.url == self.currentVlcMedia?.url?.absoluteString }).first
            self.loadArtwork(for: self.currentSong)
            self.event.send(.currentMedia(self.currentVlcMedia, self.currentSong))
            self.updateNowPlayingInfo()
        }
    }
    
    func mediaListPlayerStopped(_ player: VLCMediaListPlayer) {
        DispatchQueue.main.async {
            self.event.send(.stoppedPlayback(player))
        }
    }
    
    func mediaListPlayerFinishedPlayback(_ player: VLCMediaListPlayer) {
        DispatchQueue.main.async {
            self.event.send(.finishedPlayback(player))
        }
    }
}

// MARK: - VLCMediaPlayerDelegate Bridge
extension PlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.position = Float(self.mediaListPlayer?.mediaPlayer.position ?? 0)
            self.currentDuration = self.mediaListPlayer?.mediaPlayer.time ?? VLCTime()
            self.miliseconds = self.mediaListPlayer?.mediaPlayer.time.intValue ?? 0
            if let length = self.currentVlcMedia?.length {
                print("Length ms:", length.intValue)
            } else {
                print("currentVlcMedia hi nil hai")
            }
        }
    }
        
    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        DispatchQueue.main.async {
            self.state = newState
            if (newState == .opening || newState == .playing), self.totalDuration.intValue == 0 {
                if let length = self.currentVlcMedia?.length {
                    self.totalDuration = length
                }
            }
            self.updateNowPlayingInfo()
            if newState == .playing || newState == .opening {
                print("Media now:", self.mediaListPlayer?.mediaPlayer.media?.url ?? "still nil")
            }
        }
    }
}

// MARK: - VLCMediaDelegate Bridge
extension PlayerManager: VLCMediaDelegate {
    func mediaMetaDataDidChange(_ aMedia: VLCMedia) {
        DispatchQueue.main.async {
            self.totalDuration = aMedia.length
            switch aMedia.parsedStatus {
            case .done:
                print("Media parsed status done")
            case .pending:
                print("Media parsed status Init")
            case .failed:
                print("Media parsed status Failed")
            case .skipped:
                print("Media parsed status skipped")
            case .timeout:
                print("Media parsed status time out")
            default:
                break
            }
        }
    }
    
    func mediaDidFinishParsing(_ aMedia: VLCMedia) {
        print(aMedia.length)
    }
}
