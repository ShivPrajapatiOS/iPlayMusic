//
//  SyncService.swift
//  iPlayMusic
//
//  Created by Shiv on 12/08/26.
//

import Foundation
import RealmSwift
import Combine

enum SyncResult {
    case success
    case failure(String)
}

@MainActor
class SyncService: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var initialLoading: Bool = false
    @Published var syncError: String? = nil
    @Published var progress: Double = 0.0
    
    private var realm: Realm?
    
    init() {
        do {
            let config = SharedRealm.getSharedRealmConfiguration()
            realm = try Realm(configuration: config)
        } catch {
            print("Realm error: \(error.localizedDescription)")
        }
    }
    
    func startFullSync() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let (fetchedMyPlaylists, fetchedSongs, fetchedPlaylists, fetchedAlbums, fetchedArtists) = try await FirebaseSyncManager.shared.fetchUserSyncData()
        
        guard let realm = self.realm else { return }
        
        // 🔢 Total Count (FocusHistory include karo)
        let totalItems = fetchedMyPlaylists.count + fetchedSongs.count + fetchedPlaylists.count + fetchedAlbums.count + fetchedArtists.count
        
        guard totalItems > 0 else {
            // 🔴 DELETE MISSING FIRST
            try deleteMissingObjects(ofType: MyPlaylistRealmModel.self, firebaseIDs: Set(fetchedMyPlaylists.map { $0._id }))
            try deleteMissingObjects(ofType: SongRealmModel.self, firebaseIDs: Set(fetchedSongs.map { $0._id }))
            try deleteMissingObjects(ofType: PlaylistRealmModel.self, firebaseIDs: Set(fetchedPlaylists.map { $0._id }))
            try deleteMissingObjects(ofType: AlbumRealmModel.self, firebaseIDs: Set(fetchedAlbums.map { $0._id }))
            try deleteMissingObjects(ofType: ArtistRealmModel.self, firebaseIDs: Set(fetchedArtists.map { $0._id }))
            return
        }
        
        var processedItems = 0
        
        // MYPLAYLISTS
        try realm.write {
            realm.add(fetchedMyPlaylists, update: .modified)
        }
        processedItems += fetchedMyPlaylists.count
        await updateProgressOnMain(processed: processedItems, total: totalItems)
        
        fetchedSongs.forEach({ s in
            guard let filePath = s.localAudioFileName else { return }
            let url = AudioFileManager.shared.localFileURL(fileName: filePath)
            print(url)
        })
        // SONGS
        try realm.write {
            realm.add(fetchedSongs, update: .modified)
        }
        processedItems += fetchedSongs.count
        await updateProgressOnMain(processed: processedItems, total: totalItems)
        
        // PLAYLISTS
        try realm.write {
            realm.add(fetchedPlaylists, update: .modified)
        }
        processedItems += fetchedPlaylists.count
        await updateProgressOnMain(processed: processedItems, total: totalItems)
        
        // ALBUMS
        try realm.write {
            realm.add(fetchedAlbums, update: .modified)
        }
        processedItems += fetchedAlbums.count
        await updateProgressOnMain(processed: processedItems, total: totalItems)
        
        // ARTISTS
        try realm.write {
            realm.add(fetchedArtists, update: .modified)
        }
        processedItems += fetchedArtists.count
        await updateProgressOnMain(processed: processedItems, total: totalItems)
        
        // 🔴 DELETE MISSING AFTER
        try deleteMissingObjects(ofType: MyPlaylistRealmModel.self, firebaseIDs: Set(fetchedMyPlaylists.map { $0._id }))
        try deleteMissingObjects(ofType: SongRealmModel.self, firebaseIDs: Set(fetchedSongs.map { $0._id }))
        try deleteMissingObjects(ofType: PlaylistRealmModel.self, firebaseIDs: Set(fetchedPlaylists.map { $0._id }))
        try deleteMissingObjects(ofType: AlbumRealmModel.self, firebaseIDs: Set(fetchedAlbums.map { $0._id }))
        try deleteMissingObjects(ofType: ArtistRealmModel.self, firebaseIDs: Set(fetchedArtists.map { $0._id }))
        print("✅ Sync Complete")
    }
    
    private func updateProgressOnMain(processed: Int, total: Int) async {
        self.progress = Double(processed) / Double(total)
        await Task.yield()
    }
    
    private func deleteMissingObjects<T: Object>(ofType type: T.Type, firebaseIDs: Set<ObjectId>) throws {
        
        guard let realm = realm else { return }
        let objectsToDelete = realm.objects(type).filter("isSync == true AND isDeleted == false AND NOT (_id IN %@)", firebaseIDs)
        
        guard !objectsToDelete.isEmpty else { return }
        
        try realm.write {
            realm.delete(objectsToDelete)
        }
    }
}
