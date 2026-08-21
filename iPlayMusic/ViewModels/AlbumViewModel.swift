//
//  AlbumViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 20/07/26.
//

import SwiftUI
import Combine

class AlbumViewModel: BaseViewModel {
    
    @Published var albums: [AlbumModel] = []
    @Published var albumDetails: AlbumDetailsModel?
    
    @Published var txtSearchAlbum: String = ""
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
    
    func searchAlbums(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            albums = []
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
            try await self.service.searchAlbums(query: query, page: currentPage, limit: pageLimit)
        } onSuccess: { result in
            self.albums = result.results ?? []
            self.canLoadMore = (result.results?.count ?? 0) >= self.pageLimit
            self.isSearching = false
        }
        isSearching = false
    }
    
    func loadMoreAlbums() async {
        guard !currentQuery.isEmpty else { return }
        guard canLoadMore else { return }
        guard !isLoadingMore, !isSearching else { return }
        
        currentPage += 1
        isLoadingMore = true
        
        do {
            let result = try await service.searchAlbums(query: currentQuery, page: currentPage, limit: pageLimit)
            let newAlbums = result.results ?? []
            let existingIDs = Set(albums.map { $0.id })
            let uniqueNewAlbums = newAlbums.filter { !existingIDs.contains($0.id) }
            albums.append(contentsOf: uniqueNewAlbums)
            canLoadMore = newAlbums.count >= pageLimit
        } catch {
            currentPage -= 1
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            showError = true
        }
        
        isLoadingMore = false
    }
        
    func getAlbumDetails(_ id: String) async {
        await execute {
            try await self.service.getAlbum(id: id)
        } onSuccess: { result in
            self.albumDetails = result
        }
    }
}
