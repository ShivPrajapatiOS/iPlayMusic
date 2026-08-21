//
//  SearchViewModel.swift
//  iPlay
//
//  Created by Shiv on 06/04/26.
//

import SwiftUI
import Combine

// MARK: - Search ViewModel
//@MainActor
class SearchViewModel: BaseViewModel {
    
    @Published var allSearch: SearchAllModel?
    
    var isAllEmpty: Bool {
        return ((allSearch?.songs?.results?.isEmpty == true) && (allSearch?.albums?.results?.isEmpty == true) && (allSearch?.artists?.results?.isEmpty == true) && (allSearch?.playlists?.results?.isEmpty == true))
    }
    
    private let service: JioSaavnServiceProtocol
    
    init(service: JioSaavnServiceProtocol = JioSaavnService.shared) {
        self.service = service
    }
    
    func searchAll(query: String) async {
        await execute {
            try await self.service.searchAll(query: query)
        } onSuccess: { result in
            self.allSearch = result
        }
    }
}
