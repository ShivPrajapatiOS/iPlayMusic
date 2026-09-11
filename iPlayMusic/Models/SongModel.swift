//
//  SongModel.swift
//  iPlayMusic
//
//  Created by Shiv on 18/07/26.
//

import SwiftUI

// MARK: - Search Songs Result
struct SearchSongsResult: Decodable {
    let total: Int?
    let start: Int?
    let results: [SongModel]?
}

// MARK: - Song Model
struct SongModel: Decodable, Identifiable {
    let id: String
    let name: String?
    let type: String?
    let year: String?
    let releaseDate: String?
    let duration: Int?
    let label: String?
    let explicitContent: Bool?
    let playCount: Int?
    let language: String?
    let hasLyrics: Bool?
    let lyricsId: String?
    let url: String?
    let copyright: String?
    let album: SongAlbumModel?
    let artists: SongArtistModel?
    let image: [ImageQuality]?
    let downloadUrl: [DownloadUrl]?
    var thumbnailURL: String? { return image?.first(where: { $0.quality == .high || $0.quality == nil })?.url }
    var streamingURL: String? { return downloadUrl?.first(where: { $0.quality == .kbps320 })?.url }
}

// MARK: - Song Alnum Model
struct SongAlbumModel: Decodable {
    let id: String?
    let name: String?
    let url: String?
}


// MARK: - Song Artist Model
struct SongArtistModel: Decodable {
    let primary: [ArtistModel]?
    let featured: [ArtistModel]?
    let all: [ArtistModel]?
}

// MARK: - Image Quality
struct ImageQuality: Decodable {
    enum QualityLevel: String, Decodable {
        case low = "50x50"
        case medium = "150x150"
        case high = "500x500"
    }
    let quality: QualityLevel?
    let url: String?
}

struct DownloadUrl: Decodable {
    enum AudioQuality: String, Decodable {
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
    
    let quality: AudioQuality?
    let url: String?
}

extension SongModel {
    // MARK: - JSON Dictionary
    func toJSON() -> [String: Any] {
        return [
            "id": id,
            "name": name as Any,
            "type": type as Any,
            "year": year as Any,
            "releaseDate": releaseDate as Any,
            "duration": duration as Any,
            "label": label as Any,
            "explicitContent": explicitContent as Any,
            "playCount": playCount as Any,
            "language": language as Any,
            "hasLyrics": hasLyrics as Any,
            "lyricsId": lyricsId as Any,
            "url": url as Any,
            "copyright": copyright as Any,
            "album": [
                "id": album?.id as Any,
                "name": album?.name as Any,
                "url": album?.url as Any
            ],
            "image": image?.map {
                [
                    "quality": $0.quality?.rawValue as Any,
                    "url": $0.url as Any
                ]
            } as Any,
            "downloadUrl": downloadUrl?.map {
                [
                    "quality": $0.quality?.rawValue as Any,
                    "url": $0.url as Any
                ]
            } as Any
        ]
    }
    
    // MARK: - JSON Data
    func toData() -> Data? {
        do {
            return try JSONSerialization.data(withJSONObject: toJSON(), options: [])
        } catch {
            print("❌ Song JSON Data conversion error:", error)
            return nil
        }
    }
    
    // MARK: - JSON String
    func toJSONString() -> String? {
        guard let data = toData() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

