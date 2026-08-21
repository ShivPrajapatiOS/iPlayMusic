//
//  SongViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 19/07/26.
//

import SwiftUI
import Combine

class SongViewModel: BaseViewModel {
    
    @Published var songs: [SongModel] = []
    @Published var suggestionSongs: [SongModel] = []
    @Published var txtSearchSong: String = ""

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
    
    func searchSongs(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            songs = []
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
            try await self.service.searchSongs(query: query, page: self.currentPage, limit: self.pageLimit)
        } onSuccess: { result in
            self.songs = result.results ?? []
            self.canLoadMore = (result.results?.count ?? 0) >= self.pageLimit
            self.isSearching = false
        }

        isSearching = false
    }
    
    func loadMoreSongs() async {
        guard !currentQuery.isEmpty else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore, !isSearching else { return }

        currentPage += 1
        isLoadingMore = true

        do {
            let result = try await service.searchSongs(query: currentQuery, page: currentPage, limit: pageLimit)
            let newSongs = result.results ?? []

            // ✅ duplicate IDs filter karo jo already list me hain
            let existingIDs = Set(songs.map { $0.id })
            let uniqueNewSongs = newSongs.filter { !existingIDs.contains($0.id) }

            songs.append(contentsOf: uniqueNewSongs)
            canLoadMore = newSongs.count >= pageLimit
        } catch {
            currentPage -= 1
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }

        isLoadingMore = false
    }
    
    func getSong(id: String) async {
        await execute {
            try await self.service.getSong(id: id)
        } onSuccess: { result in
            print(result)
        }
    }
    
    func getSuggestion(songId: String) async {
        await execute {
            try await self.service.getSuggestionSongs(songId: songId, page: 0, limit: pageLimit)
        } onSuccess: { result in
            self.suggestionSongs = result
        }
    }
}
