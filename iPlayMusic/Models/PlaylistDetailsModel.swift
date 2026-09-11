//
//  PlaylistDetailsModel.swift
//  iPlayMusic
//
//  Created by Shiv on 10/08/26.
//

import SwiftUI

// MARK: - Playlist Details Model
struct PlaylistDetailsModel: Decodable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let type: String?
    let year: String?
    let playCount: String?
    let language: String?
    let explicitContent: Bool?
    let url: String?
    let songCount: Int?
    let image: [ImageQuality]?
    let songs: [SongModel]?
    let artists: [ArtistModel]?
    let subtitle: String?
    let headerDesc: String?
    let lastUpdated: String?
    let username: String?
    let firstname: String?
    let lastname: String?
    let isFollowed: Bool?
    
    var allArtists: [ArtistModel]? {
        let uniqueArtists = Dictionary((artists ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Array(uniqueArtists.values)
    }

    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high })?.url
    }
}
