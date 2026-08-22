//
//  SongSuggestionViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 21/08/26.
//

import SwiftUI
import Combine

class SongSuggestionViewModel: BaseViewModel {
    
    @Published var suggestionSongs: [SongModel] = []
    
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
    
    func getSuggestion(songId: String) async {
        await execute {
            try await self.service.getSuggestionSongs(songId: songId, page: currentPage, limit: pageLimit)
        } onSuccess: { result in
            self.suggestionSongs = result
        }
    }
}
