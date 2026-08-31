//
//  SongRealmViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 16/08/26.
//

import SwiftUI
import Combine
import RealmSwift
import Realm

class SongRealmViewModel: ObservableObject {
    
    static let shared: SongRealmViewModel = .init()
    
    var realm: Realm?
    
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false
    
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
    
    func toggleLike(song: SongModel) async throws -> SongRealmModel {
        guard let realm = self.realm else { throw RealmError.realmAccessFailed }
        
        // MARK: Case 1 — Song already Realm me hai → sirf flag toggle
        if let existing = realm.objects(SongRealmModel.self).filter("song_id == %@", song.id).first {
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
        
        // MARK: Case 2 — Naya song, pehli baar like ho raha hai
        let newSong = mapToRealmSong(from: song)
        newSong.isLike = true
        newSong.isSync = false
        
        do {
            try realm.write {
                realm.add(newSong)
            }
            return newSong.freeze()
        } catch {
            throw RealmError.writeFailed(error.localizedDescription)
        }
    }
    
    /// Kya diya gaya song currently liked hai — heart icon ka initial state set karne ke liye.
    func isSongLiked(songId: String) -> Bool {
        guard let realm = self.realm else { return false }
        return realm.objects(SongRealmModel.self).filter("song_id == %@", songId).first?.isLike ?? false
    }
}



extension SongRealmViewModel {
    
    // MARK: - ImageQuality -> ImageQualityRealmModel
    /// Diye gaye image array me se required quality (default: .high) wali image ko
    /// ImageQualityRealmModel me convert karta hai.
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
    
    // MARK: - DownloadUrl -> DownloadURLRealmModel
    /// Ek single DownloadUrl ko DownloadURLRealmModel me convert karta hai.
    func mapToRealmDownloadURL(from downloadUrl: DownloadUrl) -> DownloadURLRealmModel {
        let realmDownloadURL = DownloadURLRealmModel()
        realmDownloadURL.url = downloadUrl.url
        realmDownloadURL.quality = mapAudioQuality(downloadUrl.quality)
        return realmDownloadURL
    }
    
    /// Poore downloadUrl array ko RealmSwift.List<DownloadURLRealmModel> me convert karta hai.
    func mapToRealmDownloadURLList(from downloadUrls: [DownloadUrl]?) -> RealmSwift.List<DownloadURLRealmModel> {
        let list = RealmSwift.List<DownloadURLRealmModel>()
        downloadUrls?.forEach { list.append(mapToRealmDownloadURL(from: $0)) }
        return list
    }
    
    /// DownloadUrl.AudioQuality -> AudioQualityRealmModel enum mapping
    private func mapAudioQuality(_ quality: DownloadUrl.AudioQuality?) -> AudioQualityRealmModel? {
        switch quality {
        case .kbps12: return .kbps12
        case .kbps48: return .kbps48
        case .kbps96: return .kbps96
        case .kbps160: return .kbps160
        case .kbps320: return .kbps320
        case .none: return nil
        }
    }
    
    // MARK: - SongAlbumModel -> SongAlbumRealmModel
    func mapToRealmAlbum(from album: SongAlbumModel?) -> SongAlbumRealmModel? {
        guard let album = album else { return nil }
        
        let realmAlbum = SongAlbumRealmModel()
        realmAlbum.id = album.id
        realmAlbum.name = album.name
        realmAlbum.url = album.url
        return realmAlbum
    }
    
    // MARK: - ArtistModel -> SongArtistRealmModel
    /// Primary artist (ya koi bhi single ArtistModel) ko SongArtistRealmModel me convert karta hai.
    func mapToRealmArtist(from artist: ArtistModel?, preferredImageQuality: ImageQuality.QualityLevel = .high) -> SongArtistRealmModel? {
        guard let artist = artist else { return nil }
        
        let realmArtist = SongArtistRealmModel()
        realmArtist.id = artist.id
        realmArtist.name = artist.name
        realmArtist.role = artist.role
        realmArtist.type = artist.type
        realmArtist.url = artist.url
        realmArtist.image = mapToRealmImage(from: artist.image, preferredQuality: preferredImageQuality)
        return realmArtist
    }
    
    // MARK: - SongModel -> SongRealmModel
    /// Poore SongModel object ko SongRealmModel me convert karta hai.
    /// Isme sabhi sub-models ke liye upar wale mapper methods use hote hain.
    func mapToRealmSong(from song: SongModel, playlistId: String? = nil) -> SongRealmModel {
        let realmSong = SongRealmModel()
        realmSong.song_id = song.id
        realmSong.playlist_id = playlistId
        realmSong.name = song.name
        realmSong.type = song.type
        realmSong.year = song.year
        realmSong.releaseDate = song.releaseDate
        realmSong.duration = song.duration
        realmSong.label = song.label
        realmSong.explicitContent = song.explicitContent
        realmSong.playCount = song.playCount
        realmSong.language = song.language
        realmSong.hasLyrics = song.hasLyrics
        realmSong.lyricsId = song.lyricsId
        realmSong.url = song.url
        realmSong.copyright = song.copyright
        
        realmSong.image = mapToRealmImage(from: song.image)
        realmSong.downloadURL = mapToRealmDownloadURLList(from: song.downloadUrl)
        realmSong.album = mapToRealmAlbum(from: song.album)
        realmSong.artists = mapToRealmArtist(from: song.artists?.primary?.first)
        
        realmSong.createAt = Date()
        realmSong.updateAt = Date()
        
        return realmSong
    }
}
