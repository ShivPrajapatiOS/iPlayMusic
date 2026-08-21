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
    
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("uid") var uid: String = ""
    @AppStorage("isAnonymous") var isAnonymous: Bool = false
    @AppStorage("musicLanguage") var musicLanguage: MusicLanguage = .hindi
    @AppStorage("musicLanguage") var selectedListenMusicLanguages: Data?
    @AppStorage("isMusicLanguage") var isMusicLanguage: Bool = true
    @Published var isSplash: Bool = true
    @Published var showFullPlayer = false
    @Published var isSyncing: Bool = false
    
#if os(macOS)
    @Published var showQueuePlaylist: Bool = false
    @Published var searchTextByTab: [SideTabBar: String] = [:]
    @Published var isDetailScreenActive: Bool = false
#endif
}

extension StateManager {
#if os(macOS)
    func searchBinding(for tab: SideTabBar) -> Binding<String> {
        Binding(get: { self.searchTextByTab[tab] ?? "" }, set: { self.searchTextByTab[tab] = $0 })
    }
#endif
}
