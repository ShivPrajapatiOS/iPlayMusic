//
//  StateManager.swift
//  iPlayMusic
//
//  Created by Shiv on 16/07/26.
//

import SwiftUI
import Combine

class StateManager: ObservableObject {
    static let shared: StateManager = .init()
    
    @AppStorage("hasPurchased") var hasPurchased: Bool = false
    @AppStorage("isFreeVersion") var isFreeVersion: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("uid") var uid: String = ""
    @AppStorage("isAnonymous") var isAnonymous: Bool = false
    @AppStorage("musicLanguage") var musicLanguage: MusicLanguage = .hindi
    @AppStorage("musicLanguage") var selectedListenMusicLanguages: Data?
    @AppStorage("isMusicLanguage") var isMusicLanguage: Bool = true
    
    @Published var isSplash: Bool = true
    @Published var showFullPlayer = false
    @Published var isSyncing: Bool = false
    @Published var isShowPurchase: Bool = false
    
    var isPurchased: Bool {
        if isFreeVersion {
            return true
        }
        if hasPurchased {
            return true
        }
        return false
    }
    
#if os(macOS)
    @Published var showQueuePlaylist: Bool = false
    @Published var searchTextByTab: [SideTabBar: String] = [:]
    @Published private var detailScreenDepth: Int = 0
    
    var isDetailScreenActive: Bool {
            detailScreenDepth > 0
        }
        
        func pushDetailScreen() {
            detailScreenDepth += 1
        }
        
        func popDetailScreen() {
            detailScreenDepth = max(0, detailScreenDepth - 1)
        }
#endif
}

extension StateManager {
#if os(macOS)
    func searchBinding(for tab: SideTabBar) -> Binding<String> {
        Binding(get: { self.searchTextByTab[tab] ?? "" }, set: { self.searchTextByTab[tab] = $0 })
    }
#endif
}
