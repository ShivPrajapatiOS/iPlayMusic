//
//  SearchAllModel.swift
//  iPlayMusic
//
//  Created by Shiv on 20/08/26.
//

import SwiftUI

// MARK: - Search All API Response
//struct SearchAllAPIResponse: Decodable {
//    let success: Bool?
//    let data: SearchAllModel?
//}

// MARK: - Search All Model
struct SearchAllModel: Decodable {
    let topQuery: SearchSection?
    let songs: SearchSection?
    let albums: SearchSection?
    let artists: SearchSection?
    let playlists: SearchSection?
}

// MARK: - Search Section
struct SearchSection: Decodable {
    let results: [SearchResultModel]?
    let position: Int?
}

// MARK: - Search Result Model
struct SearchResultModel: Decodable, Identifiable {
    let id: String
    let title: String?
    let type: String?
    let description: String?
    let url: String?
    let language: String?
    let image: [ImageQuality]?

    // Song-specific
    let album: String?
    let primaryArtists: String?
    let singers: String?

    // Album-specific
    let artist: String?
    let year: String?
    let songIds: String?

    // Artist item-level position
    let position: Int?

    var thumbnailURL: String? { return image?.first(where: { $0.quality == .high })?.url }
}
