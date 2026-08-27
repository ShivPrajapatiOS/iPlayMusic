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
    case myPlaylistTable, songTable
    
    var path: String {
        switch self {
        case .myPlaylistTable: return "my_playlists"
        case .songTable: return "songs"
        }
    }
}

class FirebaseSyncManager {
    static let shared:FirebaseSyncManager = .init()
    
    
    
    init() {
//        Task {
//            do {
//                _ = try await isFreeAppVersion()
//                try await observersFreeAppVersion()
//                try await observersLiveData()
//            } catch {
//                print(error.localizedDescription)
//            }
//        }
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
}

//ye models hai realm ka and fir esme sab me ek method hai toJSON ka us se jeson banta hai usko mane SongRealmViewModel me niche SongModel type ko SongRealmModel me conver kiya hai fir usko me firebase me save karva raha hu to usme conflict ho raha hai jo mane starting me btaya tha vesa app kam karni baand kar deti hai koi asa type issue kar raha hai to file karo kya issue hai jab firebase me save hone jata hai tab ye conflict ho raha hai 

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
        }
    }
}

// MARK: - Firebase to fetch all Data
extension FirebaseSyncManager {
    func fetchUserSyncData() async throws -> (myPlaylists: [MyPlaylistRealmModel], songs: [SongRealmModel]) {
        let _ = try checkUserAuth() // Login Check
        let myPlaylistSnapshot = try await getRef(table: .myPlaylistTable).getData()
        let songSnapshot = try await getRef(table: .songTable).getData()
        
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
        
        return (myPlaylists: realmMyPlaylist, songs: realmSongs)
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
}

// MARK: - // MARK: - Local -> Cloud with Realm Sync
extension FirebaseSyncManager {
    func syncDataObjects() async throws -> (pendingMyPlaylists: [MyPlaylistRealmModel], pendingSongs: [SongRealmModel], deletedMyPlaylists: [MyPlaylistRealmModel], deletedSongs: [SongRealmModel]) {
        
        let _ = try checkUserAuth()
        guard let realm = try? await Realm(configuration: SharedRealm.getSharedRealmConfiguration()) else {
            throw RealmError.realmAccessFailed
        }
        // check Realm schema version
//        let objectSchema = realm.schema.objectSchema.first { $0.className == "GroupModel" }
//        print(objectSchema?.properties.map { $0.name })
        
        let pendingMyPlaylists = Array(realm.objects(MyPlaylistRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() })
        let pendingSongs = Array(realm.objects(SongRealmModel.self).filter("isSync == false AND isDeleted == false").map { $0.freeze() })
        
        let deletedMyPlaylists = Array(realm.objects(MyPlaylistRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        let deletedSongs = Array(realm.objects(SongRealmModel.self).filter("isDeleted == true").map { $0.freeze() })
        
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
                try await listDataSync(song: song, table: .songTable)
                guard let updateSongObject = realm.object(ofType: SongRealmModel.self, forPrimaryKey: song._id) else { throw RealmError.invalidID }
                try realm.write {
                    updateSongObject.isSync = true
                }
            } catch {
                print("❌ Error during Realm object sync: \(error.localizedDescription)")
                throw error
            }
        }
                        
        // --- 4. Step 3: Filtered Objects return ---
        return (pendingMyPlaylists, pendingSongs, deletedMyPlaylists, deletedSongs)
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
    
    private func listDataSync(song: SongRealmModel, table: FirebaseDataTable) async throws {
        let tableRef = try getRef(table: table)
        let jsonData = song.toJSON()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            tableRef.child(song._id.stringValue).updateChildValues(jsonData) { error, _ in
                if let error = error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }
}
