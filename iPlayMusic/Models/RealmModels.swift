//
//  RealmModels.swift
//  iPlayMusic
//
//  Created by Shiv on 06/08/26.
//

import SwiftUI
import Realm
import RealmSwift

// MARK: - Realm Error
enum RealmError: Error {
    case initializationFailed
    case writeFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case realmAccessFailed
    case invalidID
    case objectsNotFound(String)
    
    var localizedDescription: String {
        switch self {
        case .initializationFailed: return "Realm failed to initialize."
        case .writeFailed(let details): return "Failed to perform write operation: \(details)"
        case .updateFailed(let details): return "Failed to perform update operation: \(details)"
        case .deleteFailed(let details): return "Failed to perform delete operation: \(details)"
        case .realmAccessFailed: return "Could not access the Realm instance."
        case .invalidID: return "Invalid ID."
        case .objectsNotFound(let details): return "No objects found: \(details)"
        }
    }
}

class MyPlaylistRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var name: String
    @Persisted var desc: String?
    @Persisted var imageData: Data? = nil
    @Persisted var isLike: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted var isSync: Bool = false
    @Persisted var createAt: Date = Date()
    @Persisted var updateAt: Date = Date()
        
    func toJSON() -> [String: Any] {
        return [
            "_id": _id.stringValue,
            "name": name,
            "desc": desc ?? NSNull(),
            "imageData": imageData?.base64EncodedString() ?? NSNull(),
            "isLike": isLike,
            "createAt": createAt.timeIntervalSince1970,
            "updateAt": updateAt.timeIntervalSince1970,
            "isSync": true,
            "isDeleted": isDeleted,
        ]
    }
}

// MARK: - SongRealmModel
class SongRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var song_id: String
    @Persisted var playlist_id: String? = nil
    @Persisted var name: String?
    @Persisted var type: String?
    @Persisted var year: String?
    @Persisted var releaseDate: String?
    @Persisted var duration: Int?
    @Persisted var label: String?
    @Persisted var explicitContent: Bool?
    @Persisted var playCount: Int?
    @Persisted var language: String?
    @Persisted var hasLyrics: Bool?
    @Persisted var lyricsId: String?
    @Persisted var url: String?
    @Persisted var copyright: String?
    @Persisted var image: ImageQualityRealmModel?
    @Persisted var downloadURL: RealmSwift.List<DownloadURLRealmModel> = RealmSwift.List<DownloadURLRealmModel>()
    @Persisted var album: SongAlbumRealmModel?
    @Persisted var artists: SongArtistRealmModel?
    @Persisted var isDeleted: Bool = false
    @Persisted var isSync: Bool = false
    @Persisted var createAt: Date = Date()
    @Persisted var updateAt: Date = Date()
    @Persisted var isDownloaded: Bool = false
    @Persisted var isLike: Bool = false
    @Persisted var localAudioFileName: String? = nil
    
    func toJSON() -> [String: Any] {
        return [
            "_id": _id.stringValue,
            "song_id": song_id,
            "playlist_id": playlist_id ?? NSNull(),
            "name": name ?? NSNull(),
            "type": type ?? NSNull(),
            "year": year ?? NSNull(),
            "releaseDate": releaseDate ?? NSNull(),
            "duration": duration ?? NSNull(),
            "label": label ?? NSNull(),
            "explicitContent": explicitContent ?? NSNull(),
            "playCount": playCount ?? NSNull(),
            "language": language ?? NSNull(),
            "hasLyrics": hasLyrics ?? NSNull(),
            "lyricsId": lyricsId ?? NSNull(),
            "url": url ?? NSNull(),
            "copyright": copyright ?? NSNull(),
            "image": image?.toJSON() ?? NSNull(),
            "downloadURL": Array(downloadURL.map { $0.toJSON() }),
            "album": album?.toJSON() ?? NSNull(),
            "artists": artists?.toJSON() ?? NSNull(),
            "createAt": createAt.timeIntervalSince1970,
            "updateAt": updateAt.timeIntervalSince1970,
            "isSync": true,
            "isDeleted": isDeleted,
            "isDownloaded": isDownloaded,
            "localAudioFileName": localAudioFileName ?? NSNull(),
            "isLike": isLike,
        ]
    }
    
    func toSongModel() throws -> SongModel {
        
        var json = self.toJSON()
        
        // Realm → SongModel
        json["id"] = json["song_id"]
        json.removeValue(forKey: "song_id")
        
        json["downloadUrl"] = json["downloadURL"]
        json.removeValue(forKey: "downloadURL")
        
        if let image = json["image"] as? [String: Any] {
            json["image"] = [image]
        }
        
        return try json.decode(SongModel.self)
        
    }
}

// MARK: - ImageQualityRealmModel
class ImageQualityRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted var url: String?
    @Persisted var quality: QualityRealmLevel?
    
    func toJSON() -> [String: Any] {
        return [
            "url": url ?? NSNull(),
            "quality": quality?.rawValue ?? NSNull()
        ]
    }
}

enum QualityRealmLevel: String, CaseIterable, PersistableEnum {
    case low = "50x50"
    case medium = "150x150"
    case high = "500x500"
}


// MARK: - DownloadURLRealmModel
class DownloadURLRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted var quality: AudioQualityRealmModel?
    @Persisted var url: String?
    
    func toJSON() -> [String: Any] {
        return [
            "quality": quality?.rawValue ?? NSNull(),
            "url": url ?? NSNull()
        ]
    }
}


// MARK: - AudioQualityRealmModel
enum AudioQualityRealmModel: String, CaseIterable, PersistableEnum {
    case kbps12 = "12kbps"
    case kbps48 = "48kbps"
    case kbps96 = "96kbps"
    case kbps160 = "160kbps"
    case kbps320 = "320kbps"
    
    var title: String {
        switch self {
        case .kbps12: return "12 kbps"
        case .kbps48: return "48 kbps"
        case .kbps96: return "96 kbps"
        case .kbps160: return "160 kbps"
        case .kbps320: return "320 kbps"
        }
    }
}

// MARK: - SongAlbumRealmModel
class SongAlbumRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted var id: String?
    @Persisted var name: String?
    @Persisted var url: String?
    
    func toJSON() -> [String: Any] {
        return [
            "id": id ?? NSNull(),
            "name": name ?? NSNull(),
            "url": url ?? NSNull()
        ]
    }
}

// MARK: - SongArtistRealmModel
class SongArtistRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted var id: String?
    @Persisted var name: String?
    @Persisted var role: String?
    @Persisted var image: ImageQualityRealmModel?
    @Persisted var type: String?
    @Persisted var url: String?
    
    var thumbnailURL: String? {
        return image?.url
    }
    
    func toJSON() -> [String: Any] {
        return [
            "id": id ?? NSNull(),
            "name": name ?? NSNull(),
            "role": role ?? NSNull(),
            "image": image?.toJSON() ?? NSNull(),
            "type": type ?? NSNull(),
            "url": url ?? NSNull()
        ]
    }
}


// MARK: - PlaylistRealmModel
class PlaylistRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var playlist_id: String
    @Persisted var name: String?
    @Persisted var type: String?
    @Persisted var image: ImageQualityRealmModel?
    @Persisted var url: String?
    @Persisted var songCount: Int?
    @Persisted var language: String?
    @Persisted var explicitContent: Bool?
    @Persisted var isDeleted: Bool = false
    @Persisted var isSync: Bool = false
    @Persisted var createAt: Date = Date()
    @Persisted var updateAt: Date = Date()
    @Persisted var isLike: Bool = false
    
    func toJSON() -> [String: Any] {
        return [
            "_id": _id.stringValue,
            "playlist_id": playlist_id,
            "name": name ?? NSNull(),
            "type": type ?? NSNull(),
            "image": image?.toJSON() ?? NSNull(),
            "url": url ?? NSNull(),
            "songCount": songCount ?? NSNull(),
            "language": language ?? NSNull(),
            "explicitContent": explicitContent ?? NSNull(),
            "isDeleted": isDeleted,
            "isSync": true,
            "createAt": createAt.timeIntervalSince1970,
            "updateAt": updateAt.timeIntervalSince1970,
            "isLike": isLike,
        ]
    }
    
    func toPlaylistModel() throws -> PlaylistModel {
        
        var json = self.toJSON()
        
        // Realm → PlaylistModel
        json["id"] = json["playlist_id"]
        json.removeValue(forKey: "playlist_id")
        
        json["downloadUrl"] = json["downloadURL"]
        json.removeValue(forKey: "downloadURL")
        
        if let image = json["image"] as? [String: Any] {
            json["image"] = [image]
        }
        
        let model = try json.decode(PlaylistModel.self)
        return model
    }
}

// MARK: - AlbumRealmModel
class AlbumRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var album_id: String
    @Persisted var name: String?
    @Persisted var desc: String?
    @Persisted var url: String?
    @Persisted var year: Int?
    @Persisted var type: String?
    @Persisted var playCount: String?
    @Persisted var language: String?
    @Persisted var explicitContent: Bool?
    @Persisted var songCount: Int?
    @Persisted var image: ImageQualityRealmModel?
    @Persisted var artists: RealmSwift.List<SongArtistRealmModel> = RealmSwift.List<SongArtistRealmModel>()
    @Persisted var isDeleted: Bool = false
    @Persisted var isSync: Bool = false
    @Persisted var createAt: Date = Date()
    @Persisted var updateAt: Date = Date()
    @Persisted var isLike: Bool = false
    
    func toJSON() -> [String: Any] {
        return [
            "_id": _id.stringValue,
            "album_id": album_id,
            "name": name ?? NSNull(),
            "description": desc ?? NSNull(),
            "url": url ?? NSNull(),
            "year": year ?? NSNull(),
            "type": type ?? NSNull(),
            "playCount": playCount ?? NSNull(),
            "language": language ?? NSNull(),
            "explicitContent": explicitContent ?? NSNull(),
            "songCount": songCount ?? NSNull(),
            "image": image?.toJSON() ?? NSNull(),
            "artists": Array(artists.map { $0.toJSON() }),
            "isDeleted": isDeleted,
            "isSync": isSync,
            "createAt": createAt.timeIntervalSince1970,
            "updateAt": updateAt.timeIntervalSince1970,
            "isLike": isLike
            
        ]
    }
    
    func toAlbumModel() throws -> AlbumModel {

        var json = self.toJSON()

        // Realm album_id -> API id
        json["id"] = json["album_id"]
        json.removeValue(forKey: "album_id")

        // Image: Realm Object -> Array
        if let image = json["image"] as? [String: Any] {
            json["image"] = [image]
        }

        // Artists: Array -> AlbumArtistModel structure
        if let artists = json["artists"] as? [[String: Any]] {

            let normalizedArtists = artists.map { artist -> [String: Any] in

                var artist = artist

                // Realm mein image single object hai,
                // AlbumArtistMini mein image array hai.
                if let image = artist["image"] as? [String: Any] {
                    artist["image"] = [image]
                }

                return artist
            }

            let primary = normalizedArtists.filter {
                ($0["role"] as? String)?.lowercased() == "primary"
            }

            let featured = normalizedArtists.filter {
                ($0["role"] as? String)?.lowercased() == "featured"
            }

            json["artists"] = [
                "primary": primary,
                "featured": featured,
                "all": normalizedArtists
            ]
        }
        return try json.decode(AlbumModel.self)
    }
}


// MARK: - ArtistRealmModel
class ArtistRealmModel: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId = ObjectId.generate()
    @Persisted var artist_id: String
    @Persisted var name: String?
    @Persisted var role: String?
    @Persisted var type: String?
    @Persisted var url: String?
    @Persisted var image: ImageQualityRealmModel?
    @Persisted var isDeleted: Bool = false
    @Persisted var isSync: Bool = false
    @Persisted var createAt: Date = Date()
    @Persisted var updateAt: Date = Date()
    @Persisted var isLike: Bool = false
    
    func toJSON() -> [String: Any] {
        return [
            "_id": _id.stringValue,
            "artist_id": artist_id,
            "name": name ?? NSNull(),
            "role": role ?? NSNull(),
            "type": type ?? NSNull(),
            "url": url ?? NSNull(),
            "image": image?.toJSON() ?? NSNull(),
            "isDeleted": isDeleted,
            "isSync": true,
            "createAt": createAt.timeIntervalSince1970,
            "updateAt": updateAt.timeIntervalSince1970,
            "isLike": isLike
        ]
    }
    
    func toArtistModel() throws -> ArtistModel {
        
        var json = self.toJSON()
        
        // Realm → ArtistModel
        json["id"] = json["artist_id"]
        json.removeValue(forKey: "artist_id")
        
        json["downloadUrl"] = json["downloadURL"]
        json.removeValue(forKey: "downloadURL")
        
        if let image = json["image"] as? [String: Any] {
            json["image"] = [image]
        }
        
        let model = try json.decode(ArtistModel.self)
        return model
    }
}
