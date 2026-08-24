// JioSaavnService.swift
// High-level service layer — use this directly in your ViewModels/Views

import Foundation

// MARK: - Protocol

protocol JioSaavnServiceProtocol {
    // Search
    func searchAll(query: String) async throws -> SearchAllModel
    func searchSongs(query: String, page: Int, limit: Int) async throws -> SearchSongsResult
    func searchAlbums(query: String, page: Int, limit: Int) async throws -> SearchAlbumsResult
    func searchArtists(query: String, page: Int, limit: Int) async throws -> SearchArtistsResult
    func searchPlaylists(query: String, page: Int, limit: Int) async throws -> SearchPlaylistsResult
    
    // Songs
    func getSong(id: String) async throws -> [SongModel]
    func getSong(link: String) async throws -> [SongModel]
    func getSongs(ids: [String]) async throws -> [SongModel]
    func getSuggestionSongs(songId: String, page: Int, limit: Int) async throws -> [SongModel]
    
    // Albums
    func getAlbum(id: String) async throws -> AlbumDetailsModel
    func getAlbum(link: String) async throws -> AlbumDetailsModel
    
    // Artists
    func getArtist(id: String) async throws -> ArtistDetailsModel
    func getArtistSongs(artistId: String) async throws -> ArtistSongsResponse
    func getArtistAlbums(artistId: String) async throws -> ArtistAlbumsResponse
    
    // Playlists
    func getPlaylist(id: String) async throws -> PlaylistDetailsModel
    func getPlaylist(link: String) async throws -> PlaylistDetailsModel
}

// MARK: - Extension protocol 
extension JioSaavnServiceProtocol {
    func searchAll(query: String) async throws -> SearchAllModel {
        try await searchAll(query: query)
    }
    func searchSongs(query: String, page: Int = 0, limit: Int = 20) async throws -> SearchSongsResult {
        try await searchSongs(query: query, page: page, limit: limit)
    }
    func searchAlbums(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchAlbumsResult {
        try await searchAlbums(query: query, page: page, limit: limit)
    }
    func searchArtists(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchArtistsResult {
        try await searchArtists(query: query, page: page, limit: limit)
    }
    func searchPlaylists(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchPlaylistsResult {
        try await searchPlaylists(query: query, page: page, limit: limit)
    }
}

// MARK: - Implementation

final class JioSaavnService: JioSaavnServiceProtocol {
    
    static let shared = JioSaavnService()
    
    private let client: HTTPClient
    
    init(client: HTTPClient = .shared) {
        self.client = client
    }
    
    // MARK: - Search
    func searchAll(query: String) async throws -> SearchAllModel {
        let endpoint = JioSaavnEndpoint.searchAll(query: query).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<SearchAllModel>.self)
        return try unwrap(response.data, fallback: "Search returned no data")
    }
    
    func searchSongs(query: String, page: Int = 0, limit: Int = 20) async throws -> SearchSongsResult {
        let endpoint = JioSaavnEndpoint.searchSongs(query: query, page: page, limit: limit).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<SearchSongsResult>.self)
        return try unwrap(response.data, fallback: "Search songs returned no data")
    }
    
    func searchAlbums(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchAlbumsResult {
        let endpoint = JioSaavnEndpoint.searchAlbums(query: query, page: page, limit: limit).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<SearchAlbumsResult>.self)
        return try unwrap(response.data, fallback: "Search albums returned no data")
    }
    
    func searchArtists(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchArtistsResult {
        let endpoint = JioSaavnEndpoint.searchArtists(query: query, page: page, limit: limit).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<SearchArtistsResult>.self)
        return try unwrap(response.data, fallback: "Search artists returned no data")
    }
    
    func searchPlaylists(query: String, page: Int = 0, limit: Int = 10) async throws -> SearchPlaylistsResult {
        let endpoint = JioSaavnEndpoint.searchPlaylists(query: query, page: page, limit: limit).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<SearchPlaylistsResult>.self)
        return try unwrap(response.data, fallback: "Search playlists returned no data")
    }
    
    // MARK: - Songs
    
    func getSong(id: String) async throws -> [SongModel] {
        let endpoint = JioSaavnEndpoint.songById(id: id).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<[SongModel]>.self)
        return try unwrap(response.data, fallback: "Song not found")
    }
    
    func getSong(link: String) async throws -> [SongModel] {
        let endpoint = JioSaavnEndpoint.songByLink(link: link).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<[SongModel]>.self)
        return try unwrap(response.data, fallback: "Song not found")
    }
    
    func getSongs(ids: [String]) async throws -> [SongModel] {
        let endpoint = JioSaavnEndpoint.songsByIds(ids: ids).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<[SongModel]>.self)
        return try unwrap(response.data, fallback: "Songs not found")
    }
    
    func getSuggestionSongs(songId: String, page: Int = 0, limit: Int = 10) async throws -> [SongModel] {
        let endpoint = JioSaavnEndpoint.songsSuggestions(id: songId, page: page, limit: limit).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<[SongModel]>.self)
        return try unwrap(response.data, fallback: "Suggestion Songs not found")
    }
    
    // MARK: - Albums
    
    func getAlbum(id: String) async throws -> AlbumDetailsModel {
        let endpoint = JioSaavnEndpoint.albumById(id: id).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<AlbumDetailsModel>.self)
        return try unwrap(response.data, fallback: "Album not found")
    }
    
    func getAlbum(link: String) async throws -> AlbumDetailsModel {
        let endpoint = JioSaavnEndpoint.albumByLink(link: link).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<AlbumDetailsModel>.self)
        return try unwrap(response.data, fallback: "Album not found")
    }
    
    // MARK: - Artists
    
    func getArtist(id: String) async throws -> ArtistDetailsModel {
        let endpoint = JioSaavnEndpoint.artistById(id: id).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<ArtistDetailsModel>.self)
        return try unwrap(response.data, fallback: "Artist not found")
    }
    
    func getArtistSongs(artistId: String) async throws -> ArtistSongsResponse {
        let endpoint = JioSaavnEndpoint.artistSongs(artistId: artistId).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<ArtistSongsResponse>.self)
        return try unwrap(response.data, fallback: "Artist songs not found")
    }
    
    func getArtistAlbums(artistId: String) async throws -> ArtistAlbumsResponse {
        let endpoint = JioSaavnEndpoint.artistAlbums(artistId: artistId).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<ArtistAlbumsResponse>.self)
        return try unwrap(response.data, fallback: "Artist albums not found")
    }
    
    // MARK: - Playlists
    
    func getPlaylist(id: String) async throws -> PlaylistDetailsModel {
        let endpoint = JioSaavnEndpoint.playlistById(id: id).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<PlaylistDetailsModel>.self)
        return try unwrap(response.data, fallback: "Playlist not found")
    }
    
    func getPlaylist(link: String) async throws -> PlaylistDetailsModel {
        let endpoint = JioSaavnEndpoint.playlistByLink(link: link).endpoint
        let response = try await client.get(endpoint, responseType: APIResponse<PlaylistDetailsModel>.self)
        return try unwrap(response.data, fallback: "Playlist not found")
    }
    
    // MARK: - Helper
    
    private func unwrap<T>(_ value: T?, fallback: String) throws -> T {
        guard let value = value else {
            throw APIError.serverError(statusCode: 200, message: fallback)
        }
        return value
    }
}
