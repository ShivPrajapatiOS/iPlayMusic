//
//  AlbumDetailsModel.swift
//  iPlayMusic
//
//  Created by Shiv on 10/08/26.
//

import SwiftUI

struct AlbumDetailsModel: Decodable {
    let id: String
    let name: String?
    let description: String?
    let type: String?
    let year: Int?
    let playCount: Int?
    let language: String?
    let explicitContent: Bool?
    let url: String?
    let songCount: Int?
    let artists: AlbumDetailsArtistModel?
    let image: [ImageQuality]?
    let songs: [SongModel]?
    
    var allArtists: [ArtistModel]? {
        let all = (artists?.all ?? [])
            + (artists?.featured ?? [])
            + (artists?.primary ?? [])

        let uniqueArtists = Dictionary(
            all.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return Array(uniqueArtists.values)
    }
    
    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high })?.url
    }
}


// MARK: - Song Artist Model
struct AlbumDetailsArtistModel: Decodable {
    let primary: [ArtistModel]?
    let featured: [ArtistModel]?
    let all: [ArtistModel]?
}
