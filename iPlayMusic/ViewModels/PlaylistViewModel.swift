//
//  PlaylistViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 21/07/26.
//

import SwiftUI
import Combine

class PlaylistViewModel: BaseViewModel {
    @Published var playlists: [PlaylistModel] = []
    @Published var detailsPlaylist: PlaylistDetailsModel?
    
    @Published var txtSearchPlaylist: String = ""
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
    
    func searchPlaylists(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            playlists = []
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
            try await self.service.searchPlaylists(query: query, page: currentPage, limit: pageLimit)
        } onSuccess: { result in
            self.playlists = result.results ?? []
            self.canLoadMore = (result.results?.count ?? 0) >= self.pageLimit
            self.isSearching = false
        }
        isSearching = false
    }
    
    func loadMorePlaylists() async {
        guard !currentQuery.isEmpty else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore, !isSearching else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        do {
            let result = try await service.searchPlaylists(query: currentQuery, page: currentPage, limit: pageLimit)
            let newPlaylists = result.results ?? []
            let existingIDs = Set(playlists.map { $0.id })
            let uniqueNewPlaylists = newPlaylists.filter { !existingIDs.contains($0.id) }
            playlists.append(contentsOf: uniqueNewPlaylists)
            canLoadMore = newPlaylists.count >= pageLimit
        } catch {
            currentPage -= 1
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        
        isLoadingMore = false
    }
    
    func getPlaylistDetails(_ id: String) async {
        await execute {
            try await self.service.getPlaylist(id: id)
        } onSuccess: { result in
            self.detailsPlaylist = result
        }

    }
}
