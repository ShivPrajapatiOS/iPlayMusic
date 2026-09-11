//
//  ArtistDetailsModel.swift
//  iPlayMusic
//
//  Created by Shiv on 21/07/26.
//

import SwiftUI
import Combine

struct ArtistDetailsModel: Decodable {
    let id: String
    let name: String?
    let url: String?
    let type: String?
    let followerCount: Int?
    let fanCount: String?
    let isVerified: Bool?
    let dominantLanguage: String?
    let dominantType: String?
    let bio: [ArtistBioModel]?
    let dob: String?
    let fb: String?
    let twitter: String?
    let wiki: String?
    let availableLanguages: [String]?
    let isRadioPresent: Bool?
    let image: [ImageQuality]?
    let topSongs: [SongModel]?
    var thumbnailURL: String? {
        return image?.first(where: { $0.quality == .high })?.url
    }
    
}

struct ArtistBioModel: Decodable {
    let text: String?
    let sequence: Int?
    let title: String?
}
