//
//  AlbumRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 29/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm

class AlbumRealmViewModel: ObservableObject {
    static let shared: AlbumRealmViewModel = .init()
    
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
    
    func toggleLikeAlbum(album: AlbumModel) async throws -> AlbumRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        
        // MARK: Case 1 — Album already Realm me hai → sirf flag toggle
        if let existing = realm.objects(AlbumRealmModel.self).filter("album_id == %@", album.id).first {
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
        
        // MARK: Case 2 — Naya Album, pehli baar like ho raha hai
        let newNewAlbum = mapToRealmAlbum(from: album)
        newNewAlbum.isLike = true
        newNewAlbum.isSync = false
        
        do {
            try realm.write {
                realm.add(newNewAlbum)
            }
            return newNewAlbum.freeze()
        } catch {
            throw RealmError.writeFailed(error.localizedDescription)
        }
    }
    
    func isAlbumLiked(albumId: String) -> Bool {
        guard let realm = self.realm else { return false }
        return realm.objects(AlbumRealmModel.self).filter("album_id == %@", albumId).first?.isLike ?? false
    }
}

extension AlbumRealmViewModel {
    func mapToRealmAlbum(from album: AlbumModel) -> AlbumRealmModel {
        let realmAlbum = AlbumRealmModel()
        realmAlbum.album_id = album.id
        realmAlbum.name = album.name
        realmAlbum.desc = album.description
        realmAlbum.year = album.year
        realmAlbum.url = album.url
        realmAlbum.type = album.type
        realmAlbum.playCount = album.playCount
        realmAlbum.language = album.language
        realmAlbum.explicitContent = album.explicitContent
        realmAlbum.songCount = album.songCount
        realmAlbum.image = mapToRealmImage(from: album.image)
        realmAlbum.artists.append(objectsIn: mapToRealmArtist(from: album.artists))
        return realmAlbum
    }
    
    private func mapToRealmImage(from images: [ImageQuality]?, preferredQuality: ImageQuality.QualityLevel = .high) -> ImageQualityRealmModel? {
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
    
    private func mapToRealmArtist(from artist: AlbumArtistModel?) -> [SongArtistRealmModel] {

        guard let artist else { return [] }

        let allArtists = (artist.primary ?? []) + (artist.featured ?? []) + (artist.all ?? [])

        var seenIDs = Set<String>()

        return allArtists.compactMap { artist in
            seenIDs.insert(artist.id)
            let realmArtist = SongArtistRealmModel()
            realmArtist.id = artist.id
            realmArtist.name = artist.name
            realmArtist.role = artist.role
            realmArtist.type = artist.type
            realmArtist.url = artist.url
            realmArtist.image = mapToRealmImage(from: artist.image)

            return realmArtist
        }
    }
}
