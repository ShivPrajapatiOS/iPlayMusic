//
//  ArtistViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 19/07/26.
//

import SwiftUI
import Combine

class ArtistViewModel: BaseViewModel {
    @Published var artists: [ArtistModel] = []
    @Published var artistInfo: ArtistDetailsModel?
    
    @Published var txtSearchArtist: String = ""
    
    @Published var isSearching: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var canLoadMore: Bool = true
    
    private let service: JioSaavnServiceProtocol
    private let pageLimit: Int
    private var currentPage: Int = 0
    private var currentQuery: String = ""
    
    init(service: JioSaavnServiceProtocol = JioSaavnService.shared, pageLimit: Int = 20) {
        self.service = service
        self.pageLimit = pageLimit
    }
    
    
    func searchArtists(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            artists = []
            currentQuery = ""
            currentPage = 0
            canLoadMore = true
            return
        }
        
        currentQuery = query
        currentPage = 0
        canLoadMore = true
        isSearching = true
        await execute {
            try await self.service.searchArtists(query: query, page: currentPage, limit: pageLimit)
        } onSuccess: { result in
            self.artists = result.results ?? []
            self.canLoadMore = (result.results?.count ?? 0) >= self.pageLimit
            self.isSearching = false
        }
        isSearching = false
    }
    
    func loadMoreArtists() async {
        guard !currentQuery.isEmpty else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore, !isSearching else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        do {
            let result = try await service.searchArtists(query: currentQuery, page: currentPage, limit: pageLimit)
            let newArtists = result.results ?? []
            let existingIDs = Set(artists.map { $0.id })
            let uniqueNewArtists = newArtists.filter { !existingIDs.contains($0.id) }
            artists.append(contentsOf: uniqueNewArtists)
            canLoadMore = newArtists.count >= pageLimit
        } catch {
            currentPage -= 1
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        
        isLoadingMore = false
    }
    
    func loadArtist(id: String) async {
        await execute {
            try await self.service.getArtist(id: id)
        } onSuccess: { artist in
            self.artistInfo = artist
        }
    }
}


//@MainActor
class ArtistViewModell: BaseViewModel {
    
    @Published var artist: Artist?
    @Published var artistInfo: ArtistDetailsModel?
    @Published var songs: [SongModel] = []
    @Published var albums: [AlbumModel] = []
    
    private let service: JioSaavnServiceProtocol
    
    init(service: JioSaavnServiceProtocol = JioSaavnService.shared) {
        self.service = service
    }
    
    func loadArtist(id: String) async {
        await execute {
            try await self.service.getArtist(id: id)
        } onSuccess: { artist in
            self.artistInfo = artist
        }
    }
    
    func loadArtistSongs(artistId: String) async {
        await execute {
            try await self.service.getArtistSongs(artistId: artistId)
        } onSuccess: { response in
            self.songs = response.songs ?? []
        }
    }
    
    func loadArtistAlbums(artistId: String) async {
        await execute {
            try await self.service.getArtistAlbums(artistId: artistId)
        } onSuccess: { response in
            self.albums = response.albums ?? []
        }
    }
}
