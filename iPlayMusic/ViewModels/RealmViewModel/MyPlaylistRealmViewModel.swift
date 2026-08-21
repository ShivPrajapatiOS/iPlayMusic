//
//  MyPlaylistRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 11/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm

class MyPlaylistRealmViewModel: ObservableObject {
    var realm: Realm?
    
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    @Published var txtNewPlaylist: String = ""
    @Published var txtDescription: String? = nil
    @Published var imageData: Data? = nil
    
    @Published var isUpdatePlaylist: MyPlaylistRealmModel? = nil
    
    init() {
        do {
            let config = SharedRealm.getSharedRealmConfiguration()
            realm = try Realm(configuration: config)
        } catch {
            print("share Realm of initialize error: \(error.localizedDescription)")
            realm = nil
        }
    }
    
    
    // Add New Playlist
    func addNewPlaylist(name: String, description: String?, imageData: Data?, isSync: Bool = false) async throws -> MyPlaylistRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        let newPlaylist = MyPlaylistRealmModel()
        newPlaylist.name = name
        newPlaylist.desc = description
        newPlaylist.imageData = imageData
        
        do {
            try realm.write {
                realm.add(newPlaylist)
                print("New MyPlaylist added: \(name)")
            }
            return newPlaylist
        } catch {
            print("Error adding new MyPlaylist: \(error.localizedDescription)")
            throw RealmError.writeFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Update Playlist
    func updatePlaylist(playlistId: ObjectId, name: String, description: String?, imageData: Data?, isSync: Bool = false) async throws -> MyPlaylistRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        guard let playlistToUpdate = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: playlistId) else { throw RealmError.invalidID }
        
        do {
            try realm.write {
                playlistToUpdate.name = name
                playlistToUpdate.desc = description
                playlistToUpdate.imageData = imageData
                playlistToUpdate.isSync = isSync
                playlistToUpdate.updateAt = Date()
            }
            
            print("Updated MyPlaylist: \(playlistToUpdate.name)")
            return playlistToUpdate
        } catch {
            print("Error updated MyPlaylist: \(error.localizedDescription)")
            throw RealmError.updateFailed(error.localizedDescription)
        }
    }
    
    func likeUnlikePlaylist(playlistId: ObjectId, isLike: Bool) async throws -> MyPlaylistRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        guard let playlistToUpdate = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: playlistId) else { throw RealmError.invalidID }

        do {
            try realm.write {
                playlistToUpdate.isLike = isLike
                playlistToUpdate.updateAt = Date()
            }
            
            print("Updated MyPlaylist: \(playlistToUpdate.name)")
            return playlistToUpdate
        } catch {
            print("Error updated MyPlaylist: \(error.localizedDescription)")
            throw RealmError.updateFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Delete Playlist
    func softDeletePlaylistById(playlistId: ObjectId) async throws {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        guard let playlistToDelete = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: playlistId) else { throw RealmError.invalidID }
        do {
            try realm.write {
                // 1️⃣ Soft delete playlist
                playlistToDelete.isDeleted = true
                playlistToDelete.updateAt = Date()
            }
        } catch {
            throw RealmError.deleteFailed(error.localizedDescription)
        }
    }
    
    func deleteDeletePlaylistById(playlistId: ObjectId) async throws {
        // 1. Realm in ID for object find
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        guard let groupToDelete = realm.object(ofType: MyPlaylistRealmModel.self, forPrimaryKey: playlistId) else { throw RealmError.invalidID }
        let _ = try await FirebaseSyncManager.shared.deleteMyPlaylistByIdSync(groupToDelete._id.stringValue)
        do {
            try realm.write {
                realm.delete(groupToDelete) // MyPlaylist
                print("MyPlaylist deleted successfully.")
            }
        } catch {
            print("Error deleting MyPlaylist: \(error.localizedDescription)")
            throw RealmError.deleteFailed(error.localizedDescription)
        }
    }
}
