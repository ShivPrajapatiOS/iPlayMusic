//
//  SongDownloadManager.swift
//  iPlayMusic
//
//  Created by Shiv on 16/08/26.
//

import Foundation
import RealmSwift
import Combine

/// Song download flow ko orchestrate karta hai:
/// - User "download" tap kare to audio local disk par save + Realm update
/// - Doosre device par sync ke baad, jo songs `isDownloaded = true` hain
///   lekin local file missing hai, unhe automatically background me
///   re-download karta hai (JioSaavn URL se, Firebase se nahi)
@MainActor
class SongDownloadManager: ObservableObject {
    static let shared = SongDownloadManager()
    
    // Kaunse songs abhi download ho rahe hain — UI me progress/spinner dikhane ke liye
    @Published var downloadingSongIds: Set<String> = []
    
    private var realm: Realm? {
        try? Realm(configuration: SharedRealm.getSharedRealmConfiguration())
    }
    
    private init() {}
    
    // MARK: - Download a Song
    
    /// Song audio download karke local save karta hai aur Realm update karta hai.
    /// `isSync = false` set karta hai taaki tumhara existing
    /// `FirebaseSyncManager.syncDataObjects()` flow is status ko apne aap
    /// Firebase par push kar de (audio bytes nahi, sirf flag).
    func downloadSong(_ song: SongRealmModel) async throws {
        guard let remoteURLString = song.downloadURL.first(where: { $0.quality == .kbps320 })?.url, let remoteURL = URL(string: remoteURLString) else { throw SongDownloadError.missingRemoteURL }
        
        let songId = song.song_id
        downloadingSongIds.insert(songId)
        defer { downloadingSongIds.remove(songId) }
        
        let savedFileName = try await AudioFileManager.shared.downloadAudio(from: remoteURL, songId: songId)
        
        guard let realm = self.realm,
              let songToUpdate = realm.object(ofType: SongRealmModel.self, forPrimaryKey: song._id) else {
            throw RealmError.invalidID
        }
        
        try realm.write {
            songToUpdate.isDownloaded = true
            songToUpdate.localAudioFileName = savedFileName
            songToUpdate.isSync = false   // pending -> agla sync cycle Firebase par status push karega
            songToUpdate.updateAt = Date()
        }
    }
    
    // MARK: - Remove a Download
    
    /// Local audio file delete karta hai aur Realm me isDownloaded = false kar deta hai.
    /// Ye status bhi Firebase par sync hoga taaki doosre devices ko pata chale
    /// ki ab ye song downloaded nahi hai.
    func removeDownload(_ song: SongRealmModel) throws {
        AudioFileManager.shared.deleteAudio(fileName: song.localAudioFileName)
        
        guard let realm = self.realm, let songToUpdate = realm.object(ofType: SongRealmModel.self, forPrimaryKey: song._id) else { throw RealmError.invalidID }
        
        try realm.write {
            songToUpdate.isDownloaded = false
            songToUpdate.localAudioFileName = nil
            songToUpdate.isSync = false
            songToUpdate.updateAt = Date()
        }
    }
    
    // MARK: - Playback URL
    
    /// Agar song offline downloaded hai to local file URL deta hai,
    /// warna online streaming URL (JioSaavn) deta hai. Player ko yahi call karna chahiye.
    func playbackURL(for song: SongRealmModel) -> URL? {
        if song.isDownloaded, let fileName = song.localAudioFileName, AudioFileManager.shared.fileExists(fileName: fileName) { return AudioFileManager.shared.localFileURL(fileName: fileName) }
        if let remoteURLString = song.url ?? song.downloadURL.first(where: { $0.quality == .kbps320 })?.url {
            return URL(string: remoteURLString)
        }
        return nil
    }
    
    // MARK: - Auto Re-download on New Device
    
    /// Firebase se sync hone ke baad call karo (e.g. `fetchUserSyncData()` ke turant baad).
    /// Jo songs `isDownloaded = true` hain lekin is device par local file
    /// missing hai (naya device / reinstall ke case me), unhe background me
    /// automatically re-download kar deta hai.
    func autoRedownloadMissingSongs() async {
        guard let realm = self.realm else { return }
        
        let songsNeedingRedownload = realm.objects(SongRealmModel.self)
            .filter("isDownloaded == true AND isDeleted == false")
            .map { $0.freeze() }
        
        for song in songsNeedingRedownload {
            // Agar local file already maujood hai (same device par pehle se downloaded), skip karo
            if AudioFileManager.shared.fileExists(fileName: song.localAudioFileName) {
                continue
            }
            
            do {
                try await downloadSong(song)
                print("✅ Auto re-downloaded: \(song.name ?? song.song_id)")
            } catch {
                print("❌ Auto re-download failed for \(song.song_id): \(error.localizedDescription)")
                // Ek song fail ho to baaki songs ka download rukna nahi chahiye
                continue
            }
        }
    }
}

enum SongDownloadError: LocalizedError {
    case missingRemoteURL
    
    var errorDescription: String? {
        switch self {
        case .missingRemoteURL:
            return "Is song ka koi valid download URL nahi mila."
        }
    }
}

