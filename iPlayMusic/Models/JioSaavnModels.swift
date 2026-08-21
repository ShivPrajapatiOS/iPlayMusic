// JioSaavnModels.swift
// All Decodable models for JioSaavn API responses

import Foundation

// MARK: - Song

struct SongAlbum: Decodable {
    let id: String?
    let name: String?
    let url: String?
}

struct SongArtists: Decodable {
    let primary: [ArtistModel]?
    let featured: [ArtistModel]?
    let all: [ArtistModel]?
}

// MARK: - Album

// MARK: - Artist

struct Artist: Decodable, Identifiable {
    let id: String
    let name: String?
    let url: String?
    let type: String?
    let followerCount: String?
    let fanCount: String?
    let isVerified: Bool?
    let dominantLanguage: String?
    let dominantType: String?
    let bio: [ArtistBio]?
    let dob: String?
    let fb: String?
    let twitter: String?
    let wiki: String?
    let availableLanguages: [String]?
    let isRadioPresent: Bool?
    let image: [ImageQuality]?
    let topSongs: [SongModel]?
    let topAlbums: [AlbumModel]?
    let singles: [SongModel]?
    let similarArtists: [SimilarArtist]?
}

struct ArtistBio: Decodable {
    let title: String?
    let text: String?
    let sequence: Int?
}

struct SimilarArtist: Decodable, Identifiable {
    let id: String
    let name: String?
    let url: String?
    let image: [ImageQuality]?
    let languages: [String: String]?
    let entityType: String?
    let dob: String?
    let fb: String?
    let twitter: String?
    let wiki: String?
    let dominantLanguage: String?
    let dominantType: String?
    let roles: [String: String]?
}


// MARK: - Paginated Artist Content

struct ArtistSongsResponse: Decodable {
    let total: Int?
    let lastPage: Bool?
    let songs: [SongModel]?
}

struct ArtistAlbumsResponse: Decodable {
    let total: Int?
    let lastPage: Bool?
    let albums: [AlbumModel]?
}
