//
//  HomeView.swift
//  iPlayMusic
//
//  Created by Shiv on 23/07/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var vmNewRelease: NewReleaseViewModel = .shared
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    @StateObject private var vmAlbumRealm: AlbumRealmViewModel = .shared
    @StateObject private var vmPlaylistRealm: PlaylistRealmViewModel = .shared
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared
    @StateObject private var player: PlayerManager = .shared
    
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
        NavigationStack {
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
                                ForEach(Array(vmNewRelease.newSongs.enumerated()), id: \.element.id) { (index, newSong) in
                                    SongItemView(song: newSong, isLoading: $vmNewRelease.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                                        .frame(height: 55)
                                        .onTapGesture {
                                            player.setupPlay(songs: vmNewRelease.newSongs, playIndex: index)
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
                                            NavigationLink {
                                                AlbumDetailsView(album: newAlbum)
                                            } label: {
                                                AlbumItemView(album: newAlbum, isLoading: $vmNewRelease.isLoading, action: { _, _ in })
                                                    .frame(width: 150, height: 190)
                                            }
                                            .buttonStyle(.plain)
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
                                            NavigationLink {
                                                PlaylistDetailsView(playlist: newPlaylist)
                                            } label: {
                                                PlaylistItemView(playlist: newPlaylist, isLoading: $vmNewRelease.isLoading, action: { _, _ in })
                                                    .frame(width: 150, height: 190)
                                            }
                                            .buttonStyle(.plain)
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
                                            NavigationLink {
                                                ArtistDetailsView(artist: newArtist)
                                            } label: {
                                                ArtistItemView(artist: newArtist, isLoading: $vmNewRelease.isLoading, action: { artistMenuActionPerform($0, $1) })
                                                    .frame(width: 150, height: 190)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        if vmNewRelease.newReleases.isEmpty {
                            ContentUnavailableView(
                                "No yet",
                                systemImage: "music.microphone",
                                description: Text("Search for a song, artist or album or playlist to start listening.")
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
    
    private func albumMenuActionPerform(_ type: AlbumItemMenuTypes, _ album: AlbumModel) {
        switch type {
        case .play:
            print("Play")
        case .like:
            Task {
                do {
                    vmAlbumRealm.isLoading = true
                    let likedAlbum = try await vmAlbumRealm.toggleLikeAlbum(album: album)
                    print(likedAlbum.toJSON())
                    vmAlbumRealm.errorMessage = nil
                    vmAlbumRealm.isLoading = false
                    
                    if likedAlbum.isLike {
                        let tableReference = try await FirebaseSyncManager.shared.updateAlbum(album: likedAlbum)
                        print("this Object isSynced: \(tableReference)")
                    } else {
                        let tableReference = try await FirebaseSyncManager.shared.updateAlbum(album: likedAlbum)
                        print("this Object isSynced: \(tableReference)")
                    }
                    try await FirebaseSyncManager.shared.isSync(object: likedAlbum)
                } catch {
                    vmAlbumRealm.isLoading = false
                    vmAlbumRealm.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func songMenuActionPerform(_ type: SongMenuActionType, _ song: SongModel) {
        switch type {
        case .play:
            print("Play")
        case .addToMyplaylist:
            print("Add To My Playlist")
        case .addToQueue:
            print("Add To Queue")
        case .like:
            Task {
                do {
                    vmSongRealm.isLoading = true
                    let likedSong = try await vmSongRealm.toggleLike(song: song)
                    print(likedSong.toJSON())
                    vmSongRealm.errorMessage = nil
                    vmSongRealm.isLoading = false
                    
                    if likedSong.isLike {
                        // Naya like → Realm me pehli baar tha to addSong, warna updateSong
                        let tableReference = try await FirebaseSyncManager.shared.updateSong(song: likedSong)
                        print("this Object isSynced: \(tableReference)")
                    } else {
                        let tableReference = try await FirebaseSyncManager.shared.updateSong(song: likedSong)
                        print("this Object isSynced: \(tableReference)")
                    }
                    try await FirebaseSyncManager.shared.isSync(object: likedSong)
                } catch {
                    vmSongRealm.isLoading = false
                    vmSongRealm.errorMessage = error.localizedDescription
                }
            }
        case .download:
            print("Download")
        }
    }
    
    private func artistMenuActionPerform(_ type: ArtistItemMenuTypes, _ artist: ArtistModel) {
        switch type {
        case .play:
            print("Play")
        case .like:
            Task {
                do {
                    vmArtistRealm.isLoading = true
                    let likedArtist = try await vmArtistRealm.toggleLikeArtist(artist: artist)
                    vmArtistRealm.errorMessage = nil
                    vmArtistRealm.isLoading = false
                    
                    if likedArtist.isLike {
                        let tableReference = try await FirebaseSyncManager.shared.updateArtist(artist: likedArtist)
                        print("this Object isSynced: \(tableReference)")
                    } else {
                        let tableReference = try await FirebaseSyncManager.shared.updateArtist(artist: likedArtist)
                        print("this Object isSynced: \(tableReference)")
                    }
                    try await FirebaseSyncManager.shared.isSync(object: likedArtist)
                } catch {
                    vmArtistRealm.isLoading = false
                    vmArtistRealm.errorMessage = error.localizedDescription
                }
            }
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
#endif
}
