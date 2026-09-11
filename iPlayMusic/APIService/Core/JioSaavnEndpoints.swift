// JioSaavnEndpoints.swift
// All JioSaavn API endpoints defined in one place

import Foundation

// MARK: - Base Configuration
enum JioSaavnConfig {
    static let baseURL = "https://jiosaavn-api-lovat.vercel.app"
}

// MARK: - JioSaavn Endpoints
enum JioSaavnEndpoint {
    
    // MARK: - Search
    case searchAll(query: String)
    case searchSongs(query: String, page: Int = 0, limit: Int = 20)
    case searchAlbums(query: String, page: Int = 0, limit: Int = 10)
    case searchArtists(query: String, page: Int = 0, limit: Int = 10)
    case searchPlaylists(query: String, page: Int = 0, limit: Int = 10)
    
    // MARK: - Songs
    case songById(id: String)
    case songByLink(link: String)
    case songsByIds(ids: [String])
    case songsSuggestions(id: String, page: Int = 0, limit: Int = 10)
    
    // MARK: - Albums
    case albumById(id: String)
    case albumByLink(link: String)
    
    // MARK: - Artists
    case artistById(id: String)
    case artistByLink(link: String)
    case artistSongs(artistId: String)
    case artistAlbums(artistId: String)
    
    // MARK: - Playlists
    case playlistById(id: String)
    case playlistByLink(link: String)
}

// MARK: - Endpoint Builder
extension JioSaavnEndpoint {
    
    var endpoint: APIEndpoint {
        switch self {
        // ── Search ────────────────────────────────────────────────
        case .searchAll(let query):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/search",
                queryParameters: ["query": query]
            )
            
        case .searchSongs(let query, let page, let limit):
            return APIEndpoint(
                    baseURL: JioSaavnConfig.baseURL,
                    path: "/api/search/songs",
                    queryParameters: ["query": query, "page": "\(page)", "limit": "\(limit)"]
                )
            
        case .searchAlbums(let query, let page, let limit):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/search/albums",
                queryParameters: ["query": query, "page": "\(page)", "limit": "\(limit)"]
            )
            
        case .searchArtists(let query, let page, let limit):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/search/artists",
                queryParameters: ["query": query, "page": "\(page)", "limit": "\(limit)"]
            )
            
        case .searchPlaylists(let query, let page, let limit):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/search/playlists",
                queryParameters: ["query": query, "page": "\(page)", "limit": "\(limit)"]
            )
            
        // ── Songs ─────────────────────────────────────────────────
        case .songById(let id):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/songs/\(id)",
            )
            
        case .songByLink(link: let link):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/songs",
                queryParameters: ["link": link]
            )
            
        case .songsByIds(let ids):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/songs",
                queryParameters: ["ids": ids.joined(separator: ",")]
            )
                        
        case .songsSuggestions(id: let songId, let page, let limit):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/songs/\(songId)/suggestions",
                queryParameters: ["page": "\(page)", "limit": "\(limit)"]
            )
            
        // ── Albums ────────────────────────────────────────────────
        case .albumById(let id):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/albums",
                queryParameters: ["id": id]
            )
        case .albumByLink(link: let link):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/albums",
                queryParameters: ["link": link]
            )
            
        // ── Artists ───────────────────────────────────────────────
        case .artistById(let id):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/artists/\(id)"
            )
            
        case .artistByLink(let link):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/artists",
                queryParameters: ["link": link]
            )
            
        case .artistSongs(let artistId):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/artists/\(artistId)/songs"
            )
            
        case .artistAlbums(let artistId):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/artists/\(artistId)/albums"
            )
            
        // ── Playlists ─────────────────────────────────────────────
        case .playlistById(let id):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/playlists",
                queryParameters: ["id": id]
            )
        case .playlistByLink(link: let link):
            return APIEndpoint(
                baseURL: JioSaavnConfig.baseURL,
                path: "/api/playlists",
                queryParameters: ["link": link]
            )
        }
    }
}
