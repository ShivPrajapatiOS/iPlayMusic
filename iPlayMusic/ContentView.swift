//
//  ContentView.swift
//  iPlayMusic
//
//  Created by Shiv on 09/07/26.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var vmAuth: AuthenticationViewModel = .init()
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var networkManager: NetworkManager = .init()
    @StateObject private var appState: StateManager = .shared
    @StateObject private var syncManager: SyncService = .init()
    @StateObject private var vmNewRelease: NewReleaseViewModel = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
#if !os(macOS)
    @State private var selectedTab: AppTabBar = .song
    @State private var isShowSearch: Bool = false
    @Namespace private var searchAnimation
#else
    @Namespace private var playerAnimation
    @State private var selectedTab: SideTabBar = .home
    @State private var showCreatePlaylist: Bool = false
    @State private var queueWidth: CGFloat = 270
    @State private var queueDragStartWidth: CGFloat = 270
    @State private var isDraggingQueue: Bool = false
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
                                .environmentObject(networkManager)
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
                .onChange(of: StateManager.shared.musicLanguage) {
                    vmNewRelease.startLoading()
                }
                .onFirstAppear {
                    vmNewRelease.startLoading()
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
            }
#else
            ZStack {
                Color.clear.ignoresSafeArea()
                HStack(spacing: 0) {
                    SideTabBarView(vmAuth: vmAuth, selectedTab: $selectedTab)
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
                            case .songs:
                                SongsView()
                                    .environmentObject(networkManager)
                            case .playlists:
                                    PlaylistView()
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
                    ZStack(alignment: .leading) {
                        QueueListPlayView(isShow: $appState.showQueuePlaylist)
                            .frame(maxHeight: .infinity)
                            .frame(width: appState.showQueuePlaylist ? queueWidth : 0)
                            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.86), value: queueWidth)
                        if appState.showQueuePlaylist {
                            Color.clear
                                .frame(width: 6)
                                .contentShape(Rectangle())
                                .onHover { hovering in
                                    if hovering {
                                        NSCursor.resizeLeftRight.set()
                                    } else {
                                        NSCursor.arrow.set()
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 1)
                                        .onChanged { value in
                                            if !isDraggingQueue {
                                                isDraggingQueue = true
                                                NSCursor.resizeLeftRight.set()
                                            }
                                            let newWidth = queueDragStartWidth - value.translation.width
                                            queueWidth = min(max(newWidth, 0), 500)
                                        }
                                        .onEnded { _ in
                                            isDraggingQueue = false
                                            NSCursor.arrow.set()
                                            if queueWidth < 100 {
                                                withAnimation(.easeInOut) {
                                                    appState.showQueuePlaylist = false
                                                    queueWidth = 270
                                                }
                                            } else {
                                                queueDragStartWidth = queueWidth
                                            }
                                        }
                                )
                        }
                    }
                }
                if appState.showFullPlayer {
                    MusicPlayerView(showQueuePlaylist: $appState.showQueuePlaylist, namespace: playerAnimation)
                        .environmentObject(appState)
                        .zIndex(100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .loadingOverlay($vmNewRelease.isNewLoading)
            .animation(.spring(response: 0.5, dampingFraction: 0.85),
                       value: appState.showFullPlayer)
            .sheet(isPresented: $showCreatePlaylist) {
                CreatePlaylistView(vmMyPlaylist: .init(), showCreatePlaylist: $showCreatePlaylist)
            }
            .sheet(isPresented: $appState.isShowPurchase, content: {
                PurchaseView()
                    .frame(width: 800, height: 475)
            })
            .onChange(of: StateManager.shared.musicLanguage) {
                vmNewRelease.startLoading()
            }
            .onFirstAppear {
                vmNewRelease.startLoading()
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
