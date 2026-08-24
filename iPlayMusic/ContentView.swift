//
//  ContentView.swift
//  iPlayMusic
//
//  Created by Shiv on 09/07/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var networkManager: NetworkManager = .init()
    @StateObject private var appState: StateManager = .shared
    @StateObject var syncManager: SyncService = .init()
    @StateObject private var vmNewRelease: NewReleaseViewModel = .init()
    
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
#if !os(macOS)
    @State private var selectedTab: AppTabBar = .home
    @State private var isShowSearch: Bool = false
    @Namespace private var searchAnimation
#else
    @Namespace private var playerAnimation
    @State private var selectedTab: SideTabBar = .home
    @State private var showCreatePlaylist: Bool = false
#endif
    
    var body: some View {
        GeometryReader { geoProxy in
#if os(iOS)
            NavigationView {
                ZStack {
                    theme.background(isDark: isDark).ignoresSafeArea()
                    Group {
                        switch selectedTab {
                        case .home:
                            HomeView(isShowSearch: $isShowSearch, namespace: searchAnimation)
                        case .song:
                            SongsView()
                        case .artist:
                            Text("Artists")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .album:
                            Text("Albums")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .playlist:
                            Text("Playlists")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    AppTabView(selectedTab: $selectedTab)
                }
                .overlay {
                    Group {
                        if isShowSearch {
                            SearchView(isShowSearch: $isShowSearch, namespace: searchAnimation)
                        }
                    }
                }
                .animation(.easeInOut, value: isShowSearch)
            }
#else
            ZStack {
                Color.clear.ignoresSafeArea()
                HStack(spacing: 0) {
                    SideTabBarView(selectedTab: $selectedTab)
                        .frame(width: 200)
                    ZStack {
                        Group {
                            switch selectedTab {
                            case .search:
                                SearchView()
                            case .home:
                                HomeView()
                            case .radio:
                                Text(selectedTab.title)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .artists:
                                ArtistView()
                            case .albums:
                                AlbumView()
                                    .environmentObject(vmNewRelease)
                            case .songs:
                                SongsView()
                                    .environmentObject(vmNewRelease)
                            case .playlists:
                                PlaylistView()
                                    .environmentObject(vmNewRelease)
                            case .myPlaylists:
                                MyPlaylistsView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top, content: {
                        if (selectedTab != .home) && (selectedTab != .search) {
                            if !appState.isDetailScreenActive {
                                HeaderView(selectedTab: $selectedTab, title: selectedTab.title, txtSearch: appState.searchBinding(for: selectedTab), showCreatePlaylist: $showCreatePlaylist)
                                    .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    })
                    .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
                    .safeAreaInset(edge: .bottom) {
                        MiniPlayerView(showQueuePlaylist: $appState.showQueuePlaylist, namespace: playerAnimation)
                            .opacity(appState.showFullPlayer ? 0 : 1)
                            .padding(.horizontal)
                    }
                    QueueListPlayView(isShow: $appState.showQueuePlaylist)
                        .frame(maxHeight: .infinity)
                        .frame(width: appState.showQueuePlaylist ? 270 : 0)
                }
                if appState.showFullPlayer {
                    MusicPlayerView(showQueuePlaylist: $appState.showQueuePlaylist, namespace: playerAnimation)
                        .environmentObject(appState)
                        .zIndex(100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.85),
                       value: appState.showFullPlayer)
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistView(vmMyPlaylist: .init(), showCreatePlaylist: $showCreatePlaylist)
            }
            .task {
                vmNewRelease.startLoading()
            }
            .onFirstAppear {
                Task {
                    do {
                        if networkManager.isConnected {
                            syncManager.isLoading = true
                            let _ = try await FirebaseSyncManager.shared.syncDataObjects()
                            try await syncManager.startFullSync()
                            syncManager.isLoading = false
                        }
                    } catch {
                        print(error.localizedDescription)
                        syncManager.isLoading = false
                    }
                }
            }
            if appState.isMusicLanguage {
                MusicLanguageView()
            }
#endif
        }
    }
}

#Preview {
    ContentView()
}
