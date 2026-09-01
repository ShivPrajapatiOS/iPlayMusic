//
//  ArtistModel.swift
//  iPlayMusic
//
//  Created by Shiv on 20/07/26.
//

import SwiftUI

// MARK: - Search Artist Result
struct SearchArtistsResult: Decodable {
    let total: Int?
    let start: Int?
    let results: [ArtistModel]?
}

// MARK: - Song Artist Mini Model
struct ArtistModel: Decodable, Identifiable {
    let id: String
    let name: String?
    let role: String?
    let image: [ImageQuality]?
    let type: String?
    let url: String?
    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high || $0.quality == nil })?.url
    }
}
