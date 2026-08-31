//
//  FirebaseSyncManager.swift
//  iPlayMusic
//
//  Created by Shiv on 05/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm
import FirebaseCore
import FirebaseDatabase

enum SyncError: Error {
    case userNotLoggedIn
    case noNetwork
}

enum FirebaseDataTable: String, Codable {
    case myPlaylistTable, playlistTable, songTable, albumTable, artistTable
    
    var path: String {
        switch self {
        case .myPlaylistTable: return "my_playlists"
        case .songTable: return "songs"
        case .playlistTable: return "playlists"
        case .albumTable: return "albums"
        case .artistTable: return "artists"
        }
    }
}

class FirebaseSyncManager {
    static let shared:FirebaseSyncManager = .init()
    
    
    
    init() {
        Task {
            do {
                try await isFreeAppVersion()
                try await observersFreeAppVersion()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func checkUserAuth() throws -> String {
        let uid = StateManager.shared.uid
        if uid.isEmpty {
            print("⚠️ Auth Error: User is not logged in.")
            throw SyncError.userNotLoggedIn
        }
        return uid
    }
    
    func getRef(table: FirebaseDataTable) throws -> DatabaseReference {
        let uid = try checkUserAuth()
        return Database.database().reference().child("users/\(uid)/\(table.path)")
    }
    
    func isFreeAppVersion() async throws {
        let uid = try checkUserAuth()
        let snapshot = try await Database.database().reference().child("users/\(uid)/isFree").getData()
        if let value = snapshot.value as? Bool {
            StateManager.shared.isFreeVersion = value
        } else {
            StateManager.shared.isFreeVersion = false
        }
    }
    
    func observersFreeAppVersion() async throws {
        let uid = try checkUserAuth() // Login Check
        Database.database().reference()
            .child("users/\(uid)/isFree")
            .observe(.value) { snapshot in
                if let value = snapshot.value as? Bool {
                    StateManager.shared.isFreeVersion = value
                } else {
                    StateManager.shared.isFreeVersion = false
                }
            }
    }
    
    // MARK: - MyPlaylist Upload Firebase methods
    func addMyPlaylistSync(_ myPlaylist: MyPlaylistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth() // Login Check
        let myPlaylistTable = try getRef(table: .myPlaylistTable)
        let myPlaylistID = myPlaylist._id.stringValue
        let newMyPlaylistJsonData = myPlaylist.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            myPlaylistTable.child(myPlaylistID).setValue(newMyPlaylistJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func updateMyPlaylistSync(_ myPlaylist: MyPlaylistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth() // Login Check
        let myPlaylistTable = try getRef(table: .myPlaylistTable)
        let myPlaylistID = myPlaylist._id.stringValue
        let updateJsonData = myPlaylist.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            myPlaylistTable.child(myPlaylistID).updateChildValues(updateJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func deleteMyPlaylistByIdSync(_ myPlaylistId: String) async throws -> DatabaseReference {
        let _ = try checkUserAuth() // Login Check
        let myPlaylistTable = try getRef(table: .myPlaylistTable)
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            myPlaylistTable.child(myPlaylistId).removeValue { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    
    // MARK: - Song Upload Firebase methods
    func addSong(song: SongRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let songTable = try getRef(table: .songTable)
        let songID = song._id.stringValue
        let songJsonData = song.toJSON()
        StateManager.shared.isSyncing = true
        
        return try await withCheckedThrowingContinuation { continuation in
            songTable.child(songID).setValue(songJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func updateSong(song: SongRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let songTable = try getRef(table: .songTable)
        let songID = song._id.stringValue
        let updateJsonData = song.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            songTable.child(songID).updateChildValues(updateJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func deleteSongByIdSync(_ songID: String) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let songTable = try getRef(table: .songTable)
        
        return try await withCheckedThrowingContinuation { continuation in
            songTable.child(songID).removeValue { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    // MARK: - Playlist Upload Firebase methods
    func addPlaylist(playlist: PlaylistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let playlistTable = try getRef(table: .playlistTable)
        let playlistID = playlist._id.stringValue
        let playlistJsonData = playlist.toJSON()
        StateManager.shared.isSyncing = true
        
        return try await withCheckedThrowingContinuation { continuation in
            playlistTable.child(playlistID).setValue(playlistJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func updatePlaylist(playlist: PlaylistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let playlistTable = try getRef(table: .playlistTable)
        let playlistID = playlist._id.stringValue
        let updateJsonData = playlist.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            playlistTable.child(playlistID).updateChildValues(updateJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func deletePlaylistByIdSync(_ playlistID: String) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let playlistTable = try getRef(table: .playlistTable)
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            playlistTable.child(playlistID).removeValue { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    // MARK: - Album Upload Firebase methods
    func addAlbum(album: AlbumRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let albumTable = try getRef(table: .albumTable)
        let albumID = album._id.stringValue
        let albumJsonData = album.toJSON()
        StateManager.shared.isSyncing = true
        
        return try await withCheckedThrowingContinuation { continuation in
            albumTable.child(albumID).setValue(albumJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func updateAlbum(album: AlbumRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let albumTable = try getRef(table: .albumTable)
        let albumID = album._id.stringValue
        let updateJsonData = album.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            albumTable.child(albumID).updateChildValues(updateJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func deleteAlbumByIdSync(_ albumID: String) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let albumTable = try getRef(table: .albumTable)
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            albumTable.child(albumID).removeValue { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    // MARK: - Artist Upload Firebase methods
    func addArtist(artist: ArtistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let artistTable = try getRef(table: .artistTable)
        let artistID = artist._id.stringValue
        let artistJsonData = artist.toJSON()
        StateManager.shared.isSyncing = true
        
        return try await withCheckedThrowingContinuation { continuation in
            artistTable.child(artistID).setValue(artistJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func updateArtist(artist: ArtistRealmModel) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let artistTable = try getRef(table: .artistTable)
        let artistID = artist._id.stringValue
        let updateJsonData = artist.toJSON()
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            artistTable.child(artistID).updateChildValues(updateJsonData) { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
    
    func deleteArtistByIdSync(_ artistID: String) async throws -> DatabaseReference {
        let _ = try checkUserAuth()
        let artistTable = try getRef(table: .artistTable)
        StateManager.shared.isSyncing = true
        return try await withCheckedThrowingContinuation { continuation in
            artistTable.child(artistID).removeValue { error, reference in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: reference)
                }
                StateManager.shared.isSyncing = false
            }
        }
    }
}

// MARK: - Upload On Firebase After Realm isSync Completed
extension FirebaseSyncManager {
    func isSync(object: Object) async throws {
        guard let realm = try? await Realm(configuration: SharedRealm.getSharedRealmConfiguration()) else { throw RealmError.realmAccessFailed }
        
        if let obj = object as? MyPlaylistRealmModel {
            guard let myPlaylistToUpdate = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: obj._id) else { throw RealmError.invalidID }
            try realm.write {
                myPlaylistToUpdate.isSync = true
            }
        }  else if let obj = object as? SongRealmModel {
            guard let songToUpdate = realm.object(ofType: SongRealmModel.self, forPrimaryKey: obj._id) else { throw RealmError.invalidID }
            try realm.write {
                songToUpdate.isSync = true
            }
        } else if let obj = object as? PlaylistRealmModel {
            guard let playlistToUpdate = realm.object(ofType: PlaylistRealmModel.self, forPrimaryKey: obj._id) else { throw RealmError.invalidID }
            try realm.write {
                playlistToUpdate.isSync = true
            }
        } else if let obj = object as? AlbumRealmModel {
            guard let albumToUpdate = realm.object(ofType: AlbumRealmModel.self, forPrimaryKey: obj._id) else { throw RealmError.invalidID }
            try realm.write {
                albumToUpdate.isSync = true
            }
        } else if let obj = object as? ArtistRealmModel {
            guard let artistToUpdate = realm.object(ofType: ArtistRealmModel.self, forPrimaryKey: obj._id) else { throw RealmError.invalidID }
            try realm.write {
                artistToUpdate.isSync = true
            }
        }
    }
}

// MARK: - Firebase to fetch all Data
extension FirebaseSyncManager {
    func fetchUserSyncData() async throws -> (myPlaylists: [MyPlaylistRealmModel], songs: [SongRealmModel], playlists: [PlaylistRealmModel], albums: [AlbumRealmModel], artists: [ArtistRealmModel]) {
        let _ = try checkUserAuth() // Login Check
        let myPlaylistSnapshot = try await getRef(table: .myPlaylistTable).getData()
        let songSnapshot = try await getRef(table: .songTable).getData()
        let playlistSnapshot = try await getRef(table: .playlistTable).getData()
        let albumSnapshot = try await getRef(table: .albumTable).getData()
        let artistSnapshot = try await getRef(table: .artistTable).getData()
        
        // 1. MyPlaylist mapping
        var realmMyPlaylist: [MyPlaylistRealmModel] = []
        if let myPlaylistChildren = myPlaylistSnapshot.children.allObjects as? [DataSnapshot] {
            for snap in myPlaylistChildren {
                if let dict = snap.value as? [String: Any],
                   let myPlaylist = mapDictToMyPlaylist(dict) {
                    realmMyPlaylist.append(myPlaylist)
                }
            }
        }
        
        // 2. Song mapping
        var realmSongs: [SongRealmModel] = []
        if let songChildren = songSnapshot.children.allObjects as? [DataSnapshot] {
            for snap in songChildren {
                if let dict = snap.value as? [String: Any],
                   let song = mapDictToSong(dict) {
                    realmSongs.append(song)
                }
            }
        }
        
        // 3. Playlist mapping
        var realmPlaylists: [PlaylistRealmModel] = []
        if let playlistChildren = playlistSnapshot.children.allObjects as? [DataSnapshot] {
            for snap in playlistChildren {
                if let dict = snap.value as? [String: Any],
                   let playlist = mapDictToPlaylist(dict) {
                    realmPlaylists.append(playlist)
                }
            }
        }
        
        // 4. Album mapping
        var realmAlbums: [AlbumRealmModel] = []
        if let albumChildren = albumSnapshot.children.allObjects as? [DataSnapshot] {
            for snap in albumChildren {
                if let dict = snap.value as? [String: Any],
                   let album = mapDictToAlbum(dict) {
                    realmAlbums.append(album)
                }
            }
        }
        
        // 5. Artist mapping
        var realmArtists: [ArtistRealmModel] = []
        if let artistChildren = artistSnapshot.children.allObjects as? [DataSnapshot] {
            for snap in artistChildren {
                if let dict = snap.value as? [String: Any],
                   let artist = mapDictToArtist(dict) {
                    realmArtists.append(artist)
                }
            }
        }
        
        return (myPlaylists: realmMyPlaylist, songs: realmSongs, playlists: realmPlaylists, albums: realmAlbums, artists: realmArtists)
    }
    
    private func mapDictToMyPlaylist(_ dict: [String: Any]) -> MyPlaylistRealmModel? {
        guard let idString = dict["_id"] as? String, let id = try? ObjectId(string: idString) else { return nil }
        let myPlaylist = MyPlaylistRealmModel()
        myPlaylist._id = id
        myPlaylist.name = dict["name"] as? String ?? ""
        myPlaylist.desc = dict["desc"] as? String ?? nil
        myPlaylist.isLike = dict["isLike"] as? Bool ?? false
        if let base64String = dict["imageData"] as? String {
            myPlaylist.imageData = Data(base64Encoded: base64String)
        } else {
            myPlaylist.imageData = nil
        }
        myPlaylist.isSync = dict["isSync"] as? Bool ?? false
        myPlaylist.isDeleted = dict["isDeleted"] as? Bool ?? false
        myPlaylist.createAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        myPlaylist.updateAt = Date(timeIntervalSince1970: dict["updateAt"] as? Double ?? Date().timeIntervalSince1970)
        return myPlaylist
    }
    
    private func mapDictToSong(_ dict: [String: Any]) -> SongRealmModel? {
        guard let idString = dict["_id"] as? String, let id = try? ObjectId(string: idString) else { return nil }
        let song = SongRealmModel()
        song._id = id
        song.song_id = dict["song_id"] as! String
        song.playlist_id = dict["playlist_id"] as? String ?? nil
        song.name = dict["name"] as? String ?? nil
        song.type = dict["type"] as? String ?? nil
        song.year = dict["year"] as? String ?? nil
        song.releaseDate = dict["releaseDate"] as? String ?? nil
        song.duration = dict["duration"] as? Int ?? nil
        song.label = dict["label"] as? String ?? nil
        song.explicitContent = dict["explicit_content"] as? Bool ?? nil
        song.playCount = dict["playCount"] as? Int ?? nil
        song.language = dict["language"] as? String ?? nil
        song.hasLyrics = dict["hasLyrics"] as? Bool ?? nil
        song.lyricsId = dict["lyricsId"] as? String ?? nil
        song.url = dict["url"] as? String ?? nil
        song.copyright = dict["copyright"] as? String ?? nil
        song.createAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        song.updateAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        song.isSync = dict["isSync"] as? Bool ?? false
        song.isDeleted = dict["isDeleted"] as? Bool ?? false
        song.isLike = dict["isLike"] as? Bool ?? false
        
        if let imageDict = dict["image"] as? [String: Any] {
            let image = ImageQualityRealmModel()
            image.quality = imageDict["quality"] as? QualityRealmLevel ?? nil
            image.url = imageDict["url"] as? String ?? nil
            song.image = image
        }
        
        if let downloadURLArray = dict["downloadURL"] as? [[String: Any]] {
            for downloadURLDict in downloadURLArray {
                let downloadURL = DownloadURLRealmModel()
                
                if let audioQuality = downloadURLDict["quality"] as? String {
                    downloadURL.quality = AudioQualityRealmModel(rawValue: audioQuality)
                }
                downloadURL.url = downloadURLDict["url"] as? String
                
                song.downloadURL.append(downloadURL)
            }
        }
        return song
    }
    
    private func mapDictToPlaylist(_ dict: [String: Any]) -> PlaylistRealmModel? {
        guard let idString = dict["_id"] as? String, let id = try? ObjectId(string: idString) else { return nil }
        let playlist = PlaylistRealmModel()
        playlist._id = id
        playlist.playlist_id = dict["playlist_id"] as! String
        playlist.name = dict["name"] as? String
        playlist.type = dict["type"] as? String
        playlist.url = dict["url"] as? String
        playlist.songCount = dict["songCount"] as? Int
        playlist.language = dict["language"] as? String
        playlist.explicitContent = dict["explicitContent"] as? Bool
        playlist.isLike = dict["isLike"] as? Bool ?? false
        playlist.isSync = dict["isSync"] as? Bool ?? false
        playlist.isDeleted = dict["isDeleted"] as? Bool ?? false
        playlist.createAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        playlist.updateAt = Date(timeIntervalSince1970: dict["updateAt"] as? Double ?? Date().timeIntervalSince1970)
        if let imageDict = dict["image"] as? [String: Any] {
            let image = ImageQualityRealmModel()
            image.quality = imageDict["quality"] as? QualityRealmLevel ?? nil
            image.url = imageDict["url"] as? String ?? nil
            playlist.image = image
        }
        return playlist
    }
    
    private func mapDictToAlbum(_ dict: [String: Any]) -> AlbumRealmModel? {
        guard let idString = dict["_id"] as? String, let id = try? ObjectId(string: idString) else { return nil }
        let album = AlbumRealmModel()
        album._id = id
        album.album_id = dict["album_id"] as! String
        album.name = dict["name"] as? String
        album.desc = dict["description"] as? String
        album.url = dict["url"] as? String
        album.year = dict["year"] as? Int
        album.type = dict["type"] as? String
        album.playCount = dict["playCount"] as? String
        album.language = dict["language"] as? String
        album.explicitContent = dict["explicitContent"] as? Bool
        album.songCount = dict["songCount"] as? Int
        album.isLike = dict["isLike"] as? Bool ?? false
        album.isSync = dict["isSync"] as? Bool ?? false
        album.isDeleted = dict["isDeleted"] as? Bool ?? false
        album.createAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        album.updateAt = Date(timeIntervalSince1970: dict["updateAt"] as? Double ?? Date().timeIntervalSince1970)
        if let imageDict = dict["image"] as? [String: Any] {
            let image = ImageQualityRealmModel()
            image.quality = imageDict["quality"] as? QualityRealmLevel ?? nil
            image.url = imageDict["url"] as? String ?? nil
            album.image = image
        }
        if let artistsArray = dict["artists"] as? [[String: Any]] {
            for artistDict in artistsArray {
                let artist = SongArtistRealmModel()
                artist.id = artistDict["id"] as? String ?? ""
                artist.name = artistDict["name"] as? String
                artist.role = artistDict["role"] as? String
                artist.type = artistDict["type"] as? String
                artist.url = artistDict["url"] as? String
                // Image
                if let imageDict = artistDict["image"] as? [String: Any] {
                    let image = ImageQualityRealmModel()
                    image.quality = imageDict["quality"] as? QualityRealmLevel
                    image.url = imageDict["url"] as? String
                    artist.image = image
                }
                album.artists.append(artist)
            }
        }
        return album
    }
    
    private func mapDictToArtist(_ dict: [String: Any]) -> ArtistRealmModel? {
        guard let idString = dict["_id"] as? String, let id = try? ObjectId(string: idString) else { return nil }
        let artist = ArtistRealmModel()
        artist._id = id
        artist.artist_id = dict["artist_id"] as! String
        artist.name = dict["name"] as? String
        artist.role = dict["role"] as? String
        artist.type = dict["type"] as? String
        artist.url = dict["url"] as? String
        artist.isLike = dict["isLike"] as? Bool ?? false
        artist.isSync = dict["isSync"] as? Bool ?? false
        artist.isDeleted = dict["isDeleted"] as? Bool ?? false
        artist.createAt = Date(timeIntervalSince1970: dict["createAt"] as? Double ?? Date().timeIntervalSince1970)
        artist.updateAt = Date(timeIntervalSince1970: dict["updateAt"] as? Double ?? Date().timeIntervalSince1970)
        if let imageDict = dict["image"] as? [String: Any] {
            let image = ImageQualityRealmModel()
            image.quality = imageDict["quality"] as? QualityRealmLevel ?? nil
            image.url = imageDict["url"] as? String ?? nil
            artist.image = image
        }
        return artist
    }
}

// MARK: - // MARK: - Local -> Cloud with Realm Sync
extension FirebaseSyncManager {
    func syncDataObjects() async throws -> (pendingMyPlaylists: [MyPlaylistRealmModel], pendingSongs: [SongRealmModel], pendingPlaylists: [PlaylistRealmModel], pendingAlbums: [AlbumRealmModel], pendingArtists: [ArtistRealmModel], deletedMyPlaylists: [MyPlaylistRealmModel], deletedSongs: [SongRealmModel], deletedPlaylists: [PlaylistRealmModel], deletedAlbums: [AlbumRealmModel], deletedArtists: [ArtistRealmModel]) {
        
        let _ = try checkUserAuth()
        guard let realm = try? await Realm(configuration: SharedRealm.getSharedRealmConfiguration()) else { throw RealmError.realmAccessFailed }
        // check Realm schema version
//        let objectSchema = realm.schema.objectSchema.first { $0.className == "GroupModel" }
//        print(objectSchema?.properties.map { $0.name })
        
        // Pending Objects
        let pendingMyPlaylists = Array(realm.objects(MyPlaylistRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() })
        let pendingSongs = Array(realm.objects(SongRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() })
        let pedingPlaylists = Array(Array(realm.objects(PlaylistRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() }))
        let pendingAlbums = Array(Array(realm.objects(AlbumRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() }))
        let pendingArtists = Array(Array(realm.objects(ArtistRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() }))
        
        // Deleting Objects
        let deletedMyPlaylists = Array(realm.objects(MyPlaylistRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        let deletedSongs = Array(realm.objects(SongRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        let deletedPlaylists = Array(realm.objects(PlaylistRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        let deletedAlbums = Array(realm.objects(AlbumRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        let deletedArtists = Array(realm.objects(ArtistRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        
        // MyPlaylists Delete
        for myPlaylist in deletedMyPlaylists {
            do {
                try await deleteFromFirebaseOnly(id: myPlaylist._id.stringValue, table: .myPlaylistTable)
                guard let deleteMyPlaylistObject = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: myPlaylist._id) else { throw RealmError.invalidID }
                try realm.write {
                    realm.delete(deleteMyPlaylistObject)
                }
            } catch {
                print("❌ Error during Realm deletion sync: \(error.localizedDescription)")
                throw error
            }
            
        }
        
        // Songs Delete
        for song in deletedSongs {
            do {
                try await deleteFromFirebaseOnly(id: song._id.stringValue, table: .songTable)
                guard let deleteSongObject = realm.object(ofType: SongRealmModel.self, forPrimaryKey: song._id) else { throw RealmError.invalidID }
                try realm.write {
                    realm.delete(deleteSongObject)
                }
            } catch {
                print("❌ Error during Realm deletion sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Playlist Delete
        for playlist in deletedPlaylists {
            do {
                try await deleteFromFirebaseOnly(id: playlist._id.stringValue, table: .playlistTable)
                guard let deletePlaylistObject = realm.object(ofType: PlaylistRealmModel.self, forPrimaryKey: playlist._id) else { throw RealmError.invalidID }
                try realm.write {
                    realm.delete(deletePlaylistObject)
                }
            } catch {
                print("❌ Error during Realm deletion sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Album Delete
        for album in deletedAlbums {
            do {
                try await deleteFromFirebaseOnly(id: album._id.stringValue, table: .albumTable)
                guard let deleteAlbumObject = realm.object(ofType: AlbumRealmModel.self, forPrimaryKey: album._id) else { throw RealmError.invalidID }
                try realm.write {
                    realm.delete(deleteAlbumObject)
                }
            } catch {
                print("❌ Error during Realm deletion sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Artist Delete
        for artist in deletedArtists {
            do {
                try await deleteFromFirebaseOnly(id: artist._id.stringValue, table: .artistTable)
                guard let deleteArtistObject = realm.object(ofType: ArtistRealmModel.self, forPrimaryKey: artist._id) else { throw RealmError.invalidID }
                try realm.write {
                    realm.delete(deleteArtistObject)
                }
            } catch {
                print("❌ Error during Realm deletion sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // MyPlaylists Update
        for myPlaylist in pendingMyPlaylists {
            do {
                try await myPlaylistDataSync(myPlaylist: myPlaylist, table: .myPlaylistTable)
                guard let updateMyPlaylistObject = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: myPlaylist._id) else { throw RealmError.invalidID }
                try realm.write {
                    updateMyPlaylistObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Songs Update
        for song in pendingSongs {
            do {
                try await songDataSync(song: song, table: .songTable)
                guard let updateSongObject = realm.object(ofType: SongRealmModel.self, forPrimaryKey: song._id) else { throw RealmError.invalidID }
                try realm.write {
                    updateSongObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Playlist Update
        for playlist in pedingPlaylists {
            do {
                try await playlistDataSync(playlist: playlist, table: .playlistTable)
                guard let updatePlaylistObject = realm.object(ofType: PlaylistRealmModel.self, forPrimaryKey: playlist._id) else { throw RealmError.invalidID }
                try realm.write {
                    updatePlaylistObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Album Update
        for album in pendingAlbums {
            do {
                try await albumDataSync(album: album, table: .albumTable)
                guard let updateAlbumObject = realm.object(ofType: AlbumRealmModel.self, forPrimaryKey: album._id) else { throw RealmError.invalidID }
                try realm.write {
                    updateAlbumObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
        
        // Artist Update
        for artist in pendingArtists {
            do {
                try await artistDataSync(artist: artist, table: .artistTable)
                guard let updateArtistObject = realm.object(ofType: ArtistRealmModel.self, forPrimaryKey: artist._id) else { throw RealmError.invalidID }
                try realm.write {
                    updateArtistObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
                        
        // --- 4. Step 3: Filtered Objects return ---
        return (pendingMyPlaylists, pendingSongs, pedingPlaylists, pendingAlbums, pendingArtists, deletedMyPlaylists, deletedSongs, deletedPlaylists, deletedAlbums, deletedArtists)
    }
    
    // Helper: Firebase Delete Only
    private func deleteFromFirebaseOnly(id: String, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(id).removeValue { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    //     Helper: Firebase Update Only (isSync true karke bhej rahe hain)
    private func myPlaylistDataSync(myPlaylist: MyPlaylistRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = myPlaylist.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(myPlaylist._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    private func songDataSync(song: SongRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = song.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(song._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    private func playlistDataSync(playlist: PlaylistRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = playlist.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(playlist._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    private func albumDataSync(album: AlbumRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = album.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(album._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
    
    private func artistDataSync(artist: ArtistRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = artist.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(artist._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
}
