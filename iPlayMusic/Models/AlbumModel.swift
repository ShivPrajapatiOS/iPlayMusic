//
//  AlbumModel.swift
//  iPlayMusic
//
//  Created by Shiv on 20/07/26.
//

import SwiftUI

struct SearchAlbumsResult: Decodable {
    let total: Int?
    let start: Int?
    let results: [AlbumModel]?
}

struct AlbumModel: Decodable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let url: String?
    let year: Int?              // ✅ Int, not String
    let type: String?
    let playCount: String?      // null aata hai, optional rehne do
    let language: String?
    let explicitContent: Bool?
    let songCount: Int?
    let artists: AlbumArtistModel?
    let image: [ImageQuality]?

    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high })?.url
    }
}

struct AlbumArtistModel: Decodable {
    let primary: [AlbumArtistMini]?
    let featured: [AlbumArtistMini]?
    let all: [AlbumArtistMini]?
}

struct AlbumArtistMini: Decodable, Identifiable {
    let id: String
    let name: String?
    let role: String?
    let image: [ImageQuality]?
    let type: String?
    let url: String?
}
