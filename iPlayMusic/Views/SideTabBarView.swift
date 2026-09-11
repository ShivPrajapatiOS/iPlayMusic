//
//  SideTabBarView.swift
//  iPlayMusicMacOS
//
//  Created by Shiv on 09/07/26.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

#if os(macOS)
enum SideTabBar: String, CaseIterable {
    case search, home, radio, artists, albums, songs, playlists, myPlaylists
    
    var title: String {
        switch self {
        case .search: return "Search"
        case .home: return "Home"
        case .radio: return "Radio"
        case .artists: return "Artists"
        case .albums: return "Albums"
        case .songs: return "Songs"
        case .playlists: return "Playlists"
        case .myPlaylists: return "My Playlist"
        }
    }
    
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .home: return "music.note.house"
        case .radio: return "dot.radiowaves.left.and.right"
        case .artists: return "music.microphone"
        case .albums: return "music.note.square.stack"
        case .songs: return "music.note"
        case .playlists: return "music.note.list"
        case .myPlaylists: return "music.note.list"
        }
    }
}

struct SideTabBarView: View {
    @Environment(\.colorScheme) private var systemScheme
    @ObservedObject var vmAuth: AuthenticationViewModel
    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let mainTabs: [SideTabBar] = [.search, .home, .radio]
    let library: [SideTabBar] = [.songs, .artists, .albums]
    let playlists: [SideTabBar] = [.playlists, .myPlaylists]
    @State private var isShowSettings: Bool = false
    
    @Binding var selectedTab: SideTabBar
    
    @Namespace var animation
    
    var body: some View {
        ZStack(alignment: .top) {
            theme.background(isDark: isDark)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 3) {
                    ZStack {
                        let profileURL = Auth.auth().currentUser?.providerData.first(where: { $0.photoURL != nil })?.photoURL
                        WebImage(url: profileURL, options: [.retryFailed, .continueInBackground]) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(theme.secondaryCard(isDark: isDark))
                                .overlay {
                                    Text(String((Auth.auth().currentUser?.providerData.first(where: { $0.displayName != nil })?.displayName ?? "").uppercased().first ?? "A"))
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                }
                        }
                    }
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .background(
                        Circle().fill(theme.card(isDark: isDark))
                    )
                    .shadow(color: theme.border(isDark: isDark), radius: 10, x: 0, y: 0)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Auth.auth().currentUser?.providerData.first(where: { $0.displayName != nil })?.displayName ?? "")
                            .font(.system(size: 11, weight: .medium, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                        Text(Auth.auth().currentUser?.providerData.first(where: { $0.email != nil })?.email ?? "")
                            .font(.system(size: 8, weight: .regular, design: .default))
                            .tint(theme.subText(isDark: isDark))
                    }
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    Spacer()
                    Button {
                        isShowSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 50)
                .padding(.horizontal, 10)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(theme.background(isDark: isDark))
                        .overlay(alignment: .bottom) {
                            theme.theme.accent.opacity(0.25)
                                .frame(height: 1)
                        }
                }
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            ForEach(mainTabs, id: \.self) { tab in
                                HStack(spacing: 0) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                                        .frame(width: 35, height: 30)
                                    Text(tab.title)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .medium : .regular))
                                }
                                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                                .foregroundStyle(selectedTab == tab ? theme.theme.primary : theme.text(isDark: isDark))
                                .padding(.horizontal, 5)
                                .background {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.secondaryCard(isDark: isDark))
                                            .matchedGeometryEffect(id: "SIDE_BAR_TAB", in: animation)
                                    } else {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.background(isDark: isDark).opacity(0.0001))
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            withAnimation(.easeInOut) {
                                                selectedTab = tab
                                            }
                                        }
                                )
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("LIBRARY")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                .frame(height: 30)
                            ForEach(library, id: \.self) { tab in
                                HStack(spacing: 0) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                                        .frame(width: 35, height: 30)
                                    Text(tab.title)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .medium : .regular))
                                }
                                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                                .foregroundStyle(selectedTab == tab ? theme.theme.primary : theme.text(isDark: isDark))
                                .padding(.horizontal, 5)
                                .background {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.secondaryCard(isDark: isDark))
                                            .matchedGeometryEffect(id: "SIDE_BAR_TAB", in: animation)
                                    } else {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.background(isDark: isDark).opacity(0.0001))
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            withAnimation(.easeInOut) {
                                                selectedTab = tab
                                            }
                                        }
                                )
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("PLAYLISTS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                .frame(height: 30)
                            ForEach(playlists, id: \.self) { tab in
                                HStack(spacing: 0) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                                        .frame(width: 35, height: 30)
                                    Text(tab.title)
                                        .font(.system(size: 13, weight: selectedTab == tab ? .medium : .regular))
                                }
                                .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                                .foregroundStyle(selectedTab == tab ? theme.theme.primary : theme.text(isDark: isDark))
                                .padding(.horizontal, 5)
                                .background {
                                    if selectedTab == tab {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.secondaryCard(isDark: isDark))
                                            .matchedGeometryEffect(id: "SIDE_BAR_TAB", in: animation)
                                    } else {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(theme.background(isDark: isDark).opacity(0.0001))
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            withAnimation(.easeInOut) {
                                                selectedTab = tab
                                            }
                                        }
                                )
                            }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $isShowSettings) {
            SettingsView(vmAuth: vmAuth)
        }
    }
}
#endif

// MARK: - iOS TabBar View
#if os(iOS)
enum AppTabBar: String, CaseIterable {
    case home, song, artist, album, playlist
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .song: return "Song"
        case .artist: return "Artist"
        case .album: return "Album"
        case .playlist: return "Playlist"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .song: return "music.note"
        case .artist: return "music.microphone"
        case .album: return "music.note.square.stack"
        case .playlist: return "music.note.list"
        }
    }
    
    var iconFill: String {
        switch self {
        case .home: return "house.fill"
        case .song: return "music.note"
        case .artist: return "music.microphone"
        case .album: return "music.note.square.stack.fill"
        case .playlist: return "music.note.list"
        }
    }
}

struct AppTabView: View {
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var selectedTab: AppTabBar
    
    @Namespace private var animation
    
    
    var body: some View {
        HStack {
            ForEach(AppTabBar.allCases, id: \.self) { tab in
                VStack {
                    Image(systemName: selectedTab == tab ? tab.iconFill : tab.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(tab.title)
                        .font(.system(size: 12, weight: .medium, design: .default))
                }
                .foregroundStyle(selectedTab == tab ? theme.theme.primary : .gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial.opacity(0.00001))
                .onTapGesture {
                    withAnimation(.smooth) {
                        selectedTab = tab
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .padding(.horizontal, 7)
        .frame(height: 60)
        .background {
            ZStack {
                theme.card(isDark: isDark)
                    Image("ic_splash")
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width * 2, height: 30)
                        .opacity(0.5)
                .blendMode(.color)
                .blur(radius: 50, opaque: false)
            }
            .overlay(alignment: .top) {
                theme.border(isDark: isDark).opacity(0.5)
                    .frame(height: 1)
            }
            .ignoresSafeArea()
        }
    }
}
#endif

#Preview {
//    SideTabBarView()
    ContentView()
}
