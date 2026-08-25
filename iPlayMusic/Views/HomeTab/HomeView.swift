//
//  HomeView.swift
//  iPlayMusic
//
//  Created by Shiv on 23/07/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject var vmNewRelease: NewReleaseViewModel
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
#if os(iOS)
    @Binding var isShowSearch: Bool
    let namespace: Namespace.ID
#endif
    
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                theme.background(isDark: isDark).ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundStyle(theme.theme.primary)
                            .frame(width: 35, height: 35)
                            .background(
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.border(isDark: isDark), lineWidth: 0.25)
                                    ))
                    }
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(theme.theme.primary)
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(theme.background(isDark: isDark)))
                        .matchedGeometryEffect(id: "SEARCH_ANIMATION", in: namespace)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                isShowSearch = true
                            }
                        }
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
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 15) {
                        if !vmNewRelease.newSongs.isEmpty {
                            VStack {
                                Text("New Release Music 👇")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(height: 45)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ForEach(vmNewRelease.newSongs, id: \.id) { newSong in
                                    SongItemView(song: newSong, isLoading: $vmNewRelease.isLoading, menuAction: { _, _ in })
                                        .frame(height: 55)
                                        .onTapGesture {
//                                            Task {
//                                                await vmSuggestionSong.getSuggestion(songId: newSong.id)
//                                            }
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if !vmNewRelease.newAlbums.isEmpty {
                            VStack {
                                Text("New Albums 💿")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(height: 45)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(vmNewRelease.newAlbums, id: \.id) { newAlbum in
                                            AlbumItemView(album: newAlbum, isLoading: $vmNewRelease.isLoading)
                                                .frame(width: 150, height: 190)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        if !vmNewRelease.newPlaylists.isEmpty {
                            VStack {
                                Text("New Playlist 🎶")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(height: 45)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(vmNewRelease.newPlaylists, id: \.id) { newPlaylist in
                                            PlaylistItemView(playlist: newPlaylist, isLoading: $vmNewRelease.isLoading)
                                                .frame(width: 150, height: 190)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        if !vmNewRelease.newArtists.isEmpty {
                            VStack {
                                Text("Tranding Artist 🎙️")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(height: 45)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(vmNewRelease.newArtists, id: \.id) { newArtist in
                                            ArtistItemView(artist: newArtist, isLoading: $vmNewRelease.isLoading)
                                                .frame(width: 150, height: 190)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 16) {
                    Group {
                        Text("Home")
                            .id("Home")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .foregroundColor(theme.text(isDark: isDark))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.25), value: "Home")
                    }
                    
                    Spacer()
                    
                    HStack {
                        Menu {
                            Button {
                                print("All Albums")
                            } label: {
                                Label("All Albums", systemImage: "checkmark")
                            }
                            
                        } label: {
                            Image(systemName: "line.horizontal.3.decrease")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(theme.text(isDark: isDark))
                                .frame(width: 32.5, height: 32.5)
                                .background(
                                    Capsule()
                                        .fill(theme.background(isDark: isDark)).overlay(
                                            Capsule()
                                                .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                        ))
                        }
                        .buttonStyle(.plain)
                        
                        DropDownMusicLanguageView()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32.5)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(content: {
                    Rectangle()
                        .fill(.windowBackground)
                        .ignoresSafeArea()
                })
                .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
#endif
        }
    }
}

#if !os(macOS)
struct HomeView_Preview: View {
    @Namespace private var namespace

    var body: some View {
        HomeView(isShowSearch: .constant(false), namespace: namespace)
    }
}
#endif

#Preview {
#if !os(macOS)
    HomeView_Preview()
#else
    HomeView()
        .environmentObject(NewReleaseViewModel())
#endif
}
