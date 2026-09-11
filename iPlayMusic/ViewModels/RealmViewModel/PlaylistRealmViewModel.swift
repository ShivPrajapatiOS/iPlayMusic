//
//  PlaylistRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 28/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm

class PlaylistRealmViewModel: ObservableObject {
    static let shared: PlaylistRealmViewModel = .init()
    
    var realm: Realm?
    
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
    init() {
        do {
            let config = SharedRealm.getSharedRealmConfiguration()
            realm = try Realm(configuration: config)
        } catch {
            print("share Realm of initialize error: \(error.localizedDescription)")
            realm = nil
        }
    }
    
    func toggleLikePlaylist(playlist: PlaylistModel) async throws -> PlaylistRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        
        // MARK: Case 1 — Playlist already Realm me hai → sirf flag toggle
        if let existing = realm.objects(PlaylistRealmModel.self).filter("playlist_id == %@", playlist.id).first {
            do {
                try realm.write {
                    existing.isLike.toggle()
                    existing.isSync = false
                    existing.updateAt = Date()
                }
                return existing.freeze()
            } catch {
                throw RealmError.writeFailed(error.localizedDescription)
            }
        }
        
        // MARK: Case 2 — Naya playlist, pehli baar like ho raha hai
        let newNewPlaylist = mapToRealmPlaylist(from: playlist)
        newNewPlaylist.isLike = true
        newNewPlaylist.isSync = false
        
        do {
            try realm.write {
                realm.add(newNewPlaylist)
            }
            return newNewPlaylist.freeze()
        } catch {
            throw RealmError.writeFailed(error.localizedDescription)
        }
    }
    
    func isPlaylistLiked(playlistId: String) -> Bool {
        guard let realm = self.realm else { return false }
        return realm.objects(PlaylistRealmModel.self).filter("playlist_id == %@", playlistId).first?.isLike ?? false
    }
}

extension PlaylistRealmViewModel {
    func mapToRealmPlaylist(from playlist: PlaylistModel) -> PlaylistRealmModel {
        let realmPlaylist = PlaylistRealmModel()
        realmPlaylist.playlist_id = playlist.id
        realmPlaylist.name = playlist.name
        realmPlaylist.type = playlist.type
        realmPlaylist.image = mapToRealmImage(from: playlist.image)
        realmPlaylist.url = playlist.url
        realmPlaylist.songCount = playlist.songCount
        realmPlaylist.language = playlist.language
        realmPlaylist.explicitContent = playlist.explicitContent
        return realmPlaylist
    }
    
    func mapToRealmImage(from images: [ImageQuality]?, preferredQuality: ImageQuality.QualityLevel = .high) -> ImageQualityRealmModel? {
        guard let matchedImage = images?.first(where: { $0.quality == preferredQuality }) else { return nil }
        let realmImage = ImageQualityRealmModel()
        realmImage.url = matchedImage.url
        realmImage.quality = mapQualityLevel(matchedImage.quality)
        return realmImage
    }
    
    private func mapQualityLevel(_ level: ImageQuality.QualityLevel?) -> QualityRealmLevel? {
        switch level {
        case .low: return .low
        case .medium: return .medium
        case .high: return .high
        case .none: return nil
        }
    }
}
