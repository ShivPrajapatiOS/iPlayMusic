//
//  SearchView.swift
//  iPlayMusic
//
//  Created by Shiv on 03/08/26.
//

import SwiftUI
import SkeletonUI

struct SearchView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmAuth: AuthenticationViewModel = .init()
    @StateObject private var vmSearch: SearchViewModel = .init()

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var txtSearch: String = ""
    
#if os(iOS)
    @Binding var isShowSearch: Bool
    let namespace: Namespace.ID
#endif
    
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                theme.background(isDark: isDark).ignoresSafeArea()
                Text("Search")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 15) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .light, design: .default))
                        .foregroundStyle(theme.theme.primary)
                        .frame(width: 35, height: 35)
                        .background(
                            Capsule()
                                .fill(theme.background(isDark: isDark)).overlay(
                                    Capsule()
                                        .stroke(theme.border(isDark: isDark), lineWidth: 0.25)
                                ))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                isShowSearch = false
                            }
                        }
                    HStack {
                        TextField("Search song, artist, album, playlist", text: $txtSearch)
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundStyle(theme.subText(isDark: isDark))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .padding(.horizontal, 12.5)
                    .background(
                        Capsule()
                            .fill(theme.background(isDark: isDark)).overlay(
                                Capsule()
                                    .stroke(theme.border(isDark: isDark), lineWidth: 0.25)
                            ))
                    .matchedGeometryEffect(id: "SEARCH_ANIMATION", in: namespace)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .padding(.horizontal)
                .background {
                    theme.background(isDark: isDark).ignoresSafeArea()
                        .overlay(alignment: .bottom) {
                            theme.border(isDark: isDark)
                                .frame(height: 0.5)
                        }
                }
            }
#else
            GeometryReader { geoProxy in
                ZStack {
                    if !txtSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if !vmSearch.isAllEmpty {
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 16) {
                                    HStack(alignment: .top, spacing: 20) {
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text("TOP SEARCHED RESULTS")
                                                .font(.system(size: 15, weight: .bold, design: .default))
                                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                                .frame(height: 35)
                                            if let topResult = vmSearch.allSearch?.topQuery?.results?.first {
                                                if topResult.type == "song" {
                                                    SongSearchItemView(song: topResult, isLoading: $vmSearch.isLoading)
                                                        .frame(height: 55)
                                                } else if topResult.type == "artist" {
                                                    ArtistSearchItemView(artist: topResult, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120, height: 150)
                                                } else if topResult.type == "album" {
                                                    AlbumSearchItemView(album: topResult, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120, height: 150)
                                                } else if topResult.type == "playlist" {
                                                    PlaylistSearchItemView(playlist: topResult, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120, height: 150)
                                                }
                                            }
                                        }
                                        VStack(spacing: 0) {
                                            Text("SONGS")
                                                .font(.system(size: 15, weight: .bold, design: .default))
                                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .frame(height: 35)
                                            LazyVStack {
                                                ForEach(vmSearch.allSearch?.songs?.results ?? [], id: \.id) { song in
                                                    SongSearchItemView(song: song, isLoading: $vmSearch.isLoading)
                                                        .frame(height: 55)
                                                }
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    LazyVStack(spacing: 0) {
                                        Text("ARTISTS")
                                            .font(.system(size: 15, weight: .bold, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .frame(height: 35)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            LazyHStack(spacing: 16) {
                                                ForEach(vmSearch.allSearch?.artists?.results ?? [], id: \.id) { artist in
                                                    ArtistSearchItemView(artist: artist, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120) // Give fixed width to item
                                                }
                                            }
                                        }
                                        .frame(height: 150) // Heights define karna zaroori hai
                                    }
                                    LazyVStack(spacing: 0) {
                                        Text("ALBUMS")
                                            .font(.system(size: 15, weight: .bold, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .frame(height: 35)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            LazyHStack(spacing: 16) {
                                                ForEach(vmSearch.allSearch?.albums?.results ?? [], id: \.id) { album in
                                                    AlbumSearchItemView(album: album, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120)
                                                }
                                            }
                                        }
                                        .frame(height: 150)
                                    }
                                    
                                    LazyVStack(spacing: 0) {
                                        Text("PLAYLISTS")
                                            .font(.system(size: 15, weight: .bold, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .frame(height: 35)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            LazyHStack(spacing: 16) {
                                                ForEach(vmSearch.allSearch?.playlists?.results ?? [], id: \.id) { playlist in
                                                    PlaylistSearchItemView(playlist: playlist, isLoading: $vmSearch.isLoading)
                                                        .frame(width: 120)
                                                }
                                            }
                                        }
                                        .frame(height: 150)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40, weight: .regular, design: .default))
                                Text("Searching Your musics...")
                                    .font(.system(size: 20, weight: .bold, design: .default))
                            }
                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                        }
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40, weight: .regular, design: .default))
                            Text("Searching Your musics...")
                                .font(.system(size: 20, weight: .bold, design: .default))
                        }
                        .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top) {
                    let isEmpty = txtSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    HStack {
                        TextField("Search Anything", text: $txtSearch)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .textFieldStyle(.plain)
                            .padding(.leading, 7)
                        Button {
                            txtSearch.removeAll()
                        } label: {
                            Image(systemName: isEmpty ? "magnifyingglass" : "xmark.circle.fill")
                                .foregroundStyle(isEmpty ? theme.theme.accent : theme.subText(isDark: isDark))
                                .frame(minWidth: 25, minHeight: 25)
                                .background(Capsule().fill(Color("#000000").opacity(0.00001)))
                        }
                        .buttonStyle(.plain)
                        
                    }
                    .frame(width: geoProxy.size.width * 0.45, height: 22.5)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(theme.card(isDark: isDark))
                            .overlay {
                                Capsule()
                                    .stroke(isEmpty ? theme.border(isDark: isDark) : theme.theme.primary, lineWidth: 1)
                            }
                            .animation(.smooth, value: isEmpty)
                    }
                    .padding(.vertical, 10)
                    .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                .onChange(of: txtSearch) {
                    if !txtSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Task {
                            await vmSearch.searchAll(query: txtSearch)
                        }
                    }
                }
            }
#endif
        }
    }
}

#if !os(macOS)
struct SearchView_Preview: View {
    @Namespace private var namespace

    var body: some View {
        SearchView(isShowSearch: .constant(false), namespace: namespace)
    }
}
#endif

#Preview {
#if !os(macOS)
    SearchView_Preview()
#else
    SearchView()
#endif
}

// MARK: - Song Search Item View
struct SongSearchItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let song: SearchResultModel
    @Binding var isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangleWebImageView(url: URL(string: song.thumbnailURL ?? ""))
                .frame(width: 40, height: 40)
                .skeleton(active: isLoading)
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title ?? "Unknown")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .skeleton(active: isLoading)
                Text(song.artist ?? "Unknown")
                    .font(.system(size: 11, weight: .light, design: .default))
                    .foregroundStyle(theme.subText(isDark: isDark))
                    .skeleton(active: isLoading)
            }
            .lineLimit(1)
            
            Spacer(minLength: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 7.5)
        .background {
            RoundedRectangle(cornerRadius: 7)
                .fill(theme.background(isDark: isDark).opacity(0.5))
                .overlay {
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(theme.secondaryCard(isDark: isDark), lineWidth: 1)
                }
        }
    }
}


// MARK: - Search Artist Item View
struct ArtistSearchItemView: View {
    let artist: SearchResultModel
    @Binding var isLoading: Bool
    
    @StateObject private var theme: ThemeManager = .shared
    @Environment(\.colorScheme) private var systemScheme
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        VStack(spacing: 8) {
            CircleWebImageView(url: URL(string: artist.thumbnailURL ?? ""), thumbnail: "music.microphone")
            // Artist Title
            Text(artist.title ?? "Unknown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.text(isDark: isDark))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}


// MARK: - Search Albumt Item View
struct AlbumSearchItemView: View {
    let album: SearchResultModel
    @Binding var isLoading: Bool
    
    @StateObject private var theme: ThemeManager = .shared
    @Environment(\.colorScheme) private var systemScheme
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        VStack(spacing: 8) {
            
            RoundedRectangleWebImageView(url: URL(string: album.thumbnailURL ?? ""), thumbnail: "music.note.square.stack")
            
            // Artist Title
            Text(album.title ?? "Unknown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.text(isDark: isDark))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

// MARK: - Search Playlist Item View
struct PlaylistSearchItemView: View {
    let playlist: SearchResultModel
    @Binding var isLoading: Bool
    
    @StateObject private var theme: ThemeManager = .shared
    @Environment(\.colorScheme) private var systemScheme
    
    private let iconXFraction: CGFloat = 0.049
    private let iconYFraction: CGFloat = 0.052
    private let iconSizeFraction: CGFloat = 0.079
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangleWebImageView(url: URL(string: playlist.thumbnailURL ?? ""), thumbnail: "music.note.list")
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    GeometryReader { proxy in
                        let side = proxy.size.width
                        Image("ic_splash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color("#000000")))
                            .position(x: (side * iconXFraction) + (side * iconSizeFraction / 2), y: (side * iconYFraction) + (side * iconSizeFraction / 2))
                    }
                }
            // Artist Title
            Text(playlist.title ?? "Unknown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.text(isDark: isDark))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
