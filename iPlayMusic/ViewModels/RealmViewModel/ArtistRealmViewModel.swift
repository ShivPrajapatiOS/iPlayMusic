//
//  ArtistRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 31/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm

class ArtistRealmViewModel: ObservableObject {
    static let shared: ArtistRealmViewModel = .init()
    
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
    
    func toggleLikeArtist(artist: ArtistModel) async throws -> ArtistRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        
        // MARK: Case 1 — Album already Realm me hai → sirf flag toggle
        if let existing = realm.objects(ArtistRealmModel.self).filter("artist_id == %@", artist.id).first {
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
        let newNewArtist = mapToRealmArtist(from: artist)
        newNewArtist.isLike = true
        newNewArtist.isSync = false
        
        do {
            try realm.write {
                realm.add(newNewArtist)
            }
            return newNewArtist.freeze()
        } catch {
            throw RealmError.writeFailed(error.localizedDescription)
        }
    }
    
    func isArtistLiked(artistId: String) -> Bool {
        guard let realm = self.realm else { return false }
        return realm.objects(ArtistRealmModel.self).filter("artist_id == %@", artistId).first?.isLike ?? false
    }
}

extension ArtistRealmViewModel {
    func mapToRealmArtist(from artist: ArtistModel) -> ArtistRealmModel {
        let realmArtist = ArtistRealmModel()
        realmArtist.artist_id = artist.id
        realmArtist.name = artist.name
        realmArtist.url = artist.url
        realmArtist.role = artist.role
        realmArtist.type = artist.type
        realmArtist.image = mapToRealmImage(from: artist.image)
        return realmArtist
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
}
