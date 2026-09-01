//
//  PlaylistModel.swift
//  iPlayMusic
//
//  Created by Shiv on 21/07/26.
//

import SwiftUI

// MARK: - Search Playlist Results
struct SearchPlaylistsResult: Decodable {
    let total: Int?
    let start: Int?
    let results: [PlaylistModel]?
}

// MARK: - Playlist Model
struct PlaylistModel: Decodable, Identifiable {
    let id: String
    let name: String?
    let type: String?
    let image: [ImageQuality]?
    let url: String?
    let songCount: Int?
    let language: String?
    let explicitContent: Bool?
    
    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high || $0.quality == nil })?.url
    }
}
