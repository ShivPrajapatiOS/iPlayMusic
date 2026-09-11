//
//  MusicPlayerView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI
import VLCKit
import UniformTypeIdentifiers

enum QueueAndLyrics: String, CaseIterable {
    case playback, lyrics
    
    var title: String {
        switch self {
        case .playback: return "Playback"
        case .lyrics: return "Lyrics"
        }
    }
}

struct MusicPlayerView: View {
    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject var appState: StateManager
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    
    @State private var isLyrics: QueueAndLyrics = .playback
    @Namespace private var isLyricsAnimation

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    @Binding var showQueuePlaylist: Bool
    @State private var isLiked: Bool = false
    @State private var showEqualizer: Bool = false
    
    @State private var isShowSettings: Bool = false
        
    var namespace: Namespace.ID
    
    @State private var dropTargetIndex: Int? = nil
        
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                HStack(spacing: 0) {
                    GeometryReader { geoProxy in
                        ZStack {
                            VStack {
                                let imageSize = min(max(geoProxy.size.width * 0.4, 150), 250)
                                RoundedRectangleWebImageView(url: URL(string: player.currentSong?.thumbnailURL ?? ""), radius: 10)
                                    .frame(width: imageSize, height: imageSize)
                                    .matchedGeometryEffect(id: "PLAYER_ARTWORK", in: namespace)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .safeAreaInset(edge: .bottom) {
                                VStack(spacing: 40) {
                                    VStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(player.currentSong?.name ?? "Unknown")
                                                .font(.system(size: 18, weight: .semibold, design: .default))
                                                .foregroundStyle(theme.text(isDark: isDark))
                                                .lineLimit(1)
                                                .matchedGeometryEffect(id: "PLAYER_TITLE", in: namespace)
                                            Text(player.currentSong?.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                                                .font(.system(size: 14, weight: .regular, design: .default))
                                                .foregroundStyle(theme.subText(isDark: isDark))
                                                .lineLimit(1)
                                                .matchedGeometryEffect(id: "PLAYER_ARTIST", in: namespace)
                                        }
                                        
                                        HStack {
                                            Button {
                                                withAnimation(.bouncy) {
                                                    showEqualizer.toggle()
                                                }
                                            } label: {
                                                Image(systemName: "slider.vertical.3")
                                                    .font(.system(size: 14, weight: .light))
                                                    .foregroundColor(theme.text(isDark: isDark))
                                                    .frame(width: 32.5, height: 32.5)
                                                    .background(
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark)).overlay(
                                                                Capsule()
                                                                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                                            ))
                                            }
                                            .popover(isPresented: $showEqualizer, arrowEdge: .trailing) {
                                                EqualizerView()
                                                    .padding(20)
                                                .frame(width: 475, height: 300)
                                            }
                                            
                                            Spacer()
                                            Button {
                                                isLiked.toggle()
                                                songLikeToggle()
                                            } label: {
                                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundColor(.pink)
                                                    .frame(width: 25, height: 25)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .frame(maxWidth: .infinity)
                                    VStack(spacing: 0) {
                                        VStack(spacing: 6) {
                                            MacOSHorizontalSlider(progress:  $player.position, isHover: .constant(true)) { (progress, isTracking) in
                                                player.seek(to: progress, isTracking: isTracking)
                                            }
                                            HStack {
                                                Text(player.currentDuration.stringValue)
                                                Spacer()
                                                Text(player.totalDuration.stringValue)
                                            }
                                            .padding(.horizontal, 5)
                                            .font(.system(size: 10, weight: .light, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark))
                                        }
                                        .matchedGeometryEffect(id: "PLAYER_SEEK_SLIDER", in: namespace)
                                        HStack {
                                            Button {
                                                player.isShuffle.toggle()
                                            } label: {
                                                Image(systemName: "shuffle")
                                                    .font(.system(size: 16, weight: .light, design: .default))
                                                    .foregroundStyle(player.isShuffle ? theme.theme.primary : theme.text(isDark: isDark))
                                                    .scaledToFit()
                                                    .frame(height: 25)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                            Button {
                                                player.previousPlay()
                                            } label: {
                                                Image(systemName: "backward.fill")
                                                    .font(.system(size: 25, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 30)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .keyboardShortcut(.leftArrow, modifiers: .command)
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                player.playPause()
                                            } label: {
                                                Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                                                    .font(.system(size: 35, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(width: 35, height: 35)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .keyboardShortcut(.space, modifiers: [])
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                player.nextPlay()
                                            } label: {
                                                Image(systemName: "forward.fill")
                                                    .font(.system(size: 25, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 30)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .keyboardShortcut(.rightArrow, modifiers: .command)
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                switch player.repeatMode {
                                                case .doNotRepeat:
                                                    player.repeatMode = .repeatAllItems
                                                case .repeatAllItems:
                                                    player.repeatMode = .repeatCurrentItem
                                                case .repeatCurrentItem:
                                                    player.repeatMode = .doNotRepeat
                                                @unknown default: break;
                                                }
                                            } label: {
                                                Image(systemName: player.repeatMode == .repeatCurrentItem ? "repeat.1" : "repeat")
                                                    .font(.system(size: 16, weight: .light, design: .default))
                                                    .foregroundStyle(player.repeatMode == .doNotRepeat ? theme.text(isDark: isDark) : theme.theme.primary)
                                                    .scaledToFit()
                                                    .frame(height: 25)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .frame(maxWidth: .infinity)
                                        .matchedGeometryEffect(id: "PLAYER_CONTROLS", in: namespace)
                                    }
                                }
                            }
                            .frame(width: geoProxy.size.width * 0.75, height: geoProxy.size.height * 0.8, alignment: .top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    RoundedRectangle(cornerRadius: 0)
                        .fill(theme.border(isDark: isDark))
                        .frame(width: 1)
                        .padding(.bottom, 52.5)
                    VStack {
                        if isLyrics == .lyrics {
                            Text("Coming soon")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            if !player.queueSongsList.isEmpty {
                                ScrollView(.vertical) {
                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(player.queueSongsList.enumerated()), id: \.element.id) { (index, song) in
                                            QueueItemView(song: song)
                                                .frame(height: 50)
                                                .onDrag {
                                                    return NSItemProvider(object: song.id as NSString)
                                                }
                                                .overlay(alignment: .bottom) {
                                                    if song.id != player.queueSongsList.last?.id {
                                                        if dropTargetIndex == index {
                                                            Color.green
                                                                .frame(height: 1)
                                                        } else {
                                                            Capsule()
                                                                .fill(theme.secondaryCard(isDark: isDark).opacity(0.5))
                                                                .frame(height: 1)
                                                        }
                                                    }
                                                }
                                                .onDrop(
                                                    of: [.text],
                                                    isTargeted: Binding(
                                                        get: { dropTargetIndex == index },
                                                        set: { hovering in
                                                            if hovering {
                                                                dropTargetIndex = index
                                                            } else {
                                                                dropTargetIndex = nil
                                                            }
                                                        }
                                                    )
                                                ) { providers in
                                                    guard let provider = providers.first else { return false }
                                                    _ = provider.loadObject(ofClass: NSString.self) { value, _ in
                                                        guard let draggedId = value as? String else { return }
                                                        DispatchQueue.main.async {
                                                            player.moveSong(id: draggedId, to: index)
                                                            dropTargetIndex = nil
                                                        }
                                                    }
                                                    return true
                                                }
                                                .onTapGesture {
                                                    player.playFromPlaylist(index: index)
                                                }
                                        }
                                    }
                                    .padding(20)
                                }
                            } else {
                                ContentUnavailableView("No Songs in Queue", systemImage: "music.note.list", description: Text("Play a song to see it in your queue."))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(width: geoProxy.size.width * 0.5)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 1) {
                            ForEach(QueueAndLyrics.allCases, id: \.self) { tab in
                                Text(tab.title)
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                    .frame(maxHeight: .infinity)
                                    .padding(.horizontal, 15)
                                    .background {
                                        if isLyrics == tab {
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(theme.theme.primary)
                                                .matchedGeometryEffect(id: "ISLYRICS_SELECT_ANIMATION", in: isLyricsAnimation)
                                        } else {
                                            RoundedRectangle(cornerRadius: 5)
                                                .fill(theme.theme.lightSubText.opacity(0.000001))
                                        }
                                    }
                                    .onTapGesture {
                                        guard !player.queueSongsList.isEmpty else { return }   // 👈 tap ko yahi block kar diya
                                        withAnimation(.smooth) {
                                            isLyrics = tab
                                        }
                                    }
                            }
                        }
                        .frame(height: 27.5)
                        .padding(2.5)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(theme.secondaryCard(isDark: isDark))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                }
                        }
                        .opacity(player.queueSongsList.isEmpty ? 0.4 : 1.0)   // 👈 visual disabled look
                        .allowsHitTesting(!player.queueSongsList.isEmpty)     // 👈 extra safety — poora view hit-testing se hata do
                    }
                }
                .frame(width: geoProxy.size.width - 30, height: geoProxy.size.height - 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 16) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(theme.text(isDark: isDark))
                                .frame(width: 32.5, height: 32.5)
                                .background(
                                    Capsule()
                                        .fill(theme.background(isDark: isDark)).overlay(
                                            Capsule()
                                                .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                        ))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                                        appState.showFullPlayer = false
                                    }
                                }
                    
                    Spacer()
                    
                    HStack {
                        MacOSHorizontalSlider(progress: Binding(
                            get: { Float(player.volume) },
                            set: { player.volume = Double($0) }
                        ), isHover: .constant(true)) { (progress, isTracking) in
                            player.setVolume(progress, isTracking: isTracking)
                        }
                        Image(systemName: player.isMute ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(theme.text(isDark: isDark))
                            .onTapGesture {
                                player.isMuted()
                            }
                    }
                    .padding(.horizontal, 10)
                    .frame(width: 200, height: 32.5)
                    .background(
                        Capsule()
                            .fill(theme.background(isDark: isDark)).overlay(
                                Capsule()
                                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
                            ))
                    
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(theme.text(isDark: isDark))
                        .frame(width: 32.5, height: 32.5)
                        .background(
                            Capsule()
                                .fill(theme.background(isDark: isDark)).overlay(
                                    Capsule()
                                        .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                ))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                                isShowSettings = true
                            }
                        }
                        .popover(isPresented: $isShowSettings, arrowEdge: .trailing) {
                            PlayerSettingsView()
                        }
                }
                .frame(maxWidth: .infinity, minHeight: 32.5)
                .padding(.vertical, 10)
                .padding(.leading, 100)
                .padding(.trailing, 10)
            }
            .background(content: {
                theme.background(isDark: isDark).ignoresSafeArea()
                    .matchedGeometryEffect(id: "PLAYER_BACKGROUND", in: namespace)
            })
            .ignoresSafeArea()
            .onAppear {
                guard let song = player.currentSong else { return }
                isLiked = vmSongRealm.isSongLiked(songId: song.id)
            }
        }
    }
    
    private func songLikeToggle() {
        guard let song = player.currentSong else { return }
        Task {
            do {
                vmSongRealm.isLoading = true
                let likedSong = try await vmSongRealm.toggleLike(song: song)
                print(likedSong.toJSON())
                vmSongRealm.errorMessage = nil
                vmSongRealm.isLoading = false
                
                if likedSong.isLike {
                    // Naya like → Realm me pehli baar tha to addSong, warna updateSong
                    let tableReference = try await FirebaseSyncManager.shared.updateSong(song: likedSong)
                    print("this Object isSynced: \(tableReference)")
                } else {
                    let tableReference = try await FirebaseSyncManager.shared.updateSong(song: likedSong)
                    print("this Object isSynced: \(tableReference)")
                }
                try await FirebaseSyncManager.shared.isSync(object: likedSong)
            } catch {
                vmSongRealm.isLoading = false
                vmSongRealm.errorMessage = error.localizedDescription
            }
        }
    }
}

struct MusicPlayerView_Preview: View {
    @Namespace var animation
    var body: some View {
        MusicPlayerView(showQueuePlaylist: .constant(false), namespace: animation)
    }
}

#Preview {
    MusicPlayerView_Preview()
}
