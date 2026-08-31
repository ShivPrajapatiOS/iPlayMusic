//
//  AlbumDetailsView.swift
//  iPlayMusic
//
//  Created by Shiv on 09/08/26.
//

import SwiftUI
import SkeletonUI

struct AlbumDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared
    @StateObject private var vmAlbum: AlbumViewModel = .init()
    
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var showImage = false
    
    
    let album: AlbumModel
        
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ZStack {
                ScrollView(.vertical) {
                    VStack(spacing: 20) {
                        HStack(spacing: 25) {
                            RoundedRectangleWebImageView(url: URL(string: vmAlbum.albumDetails?.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 15)
                                .frame(width: 200, height: 200)
                                .skeleton(active: vmAlbum.isLoading)
                                .opacity(showImage ? 1 : 0)
                                .scaleEffect(showImage ? 1 : 0.9) // Optional
                                .animation(.easeOut(duration: 0.5), value: showImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vmAlbum.albumDetails?.name ?? "Unknown")
                                    .font(.system(size: 25, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                    .skeleton(active: vmAlbum.isLoading)
                                Text(vmAlbum.albumDetails?.type ?? "Unknown")
                                    .font(.system(size: 25, weight: .regular, design: .default))
                                    .foregroundStyle(theme.theme.accent)
                                    .skeleton(active: vmAlbum.isLoading)
                                Text(vmAlbum.albumDetails?.name ?? "N|A")
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .skeleton(active: vmAlbum.isLoading)
                                HStack {
                                    Button {
                                        print("play")
                                    } label: {
                                        HStack {
                                            Image(systemName: "play.fill")
                                            Text("Play")
                                        }
                                        .frame(maxHeight: .infinity)
                                        .frame(width: 135)
                                        .foregroundStyle(Color("#FFFFFF"))
                                        .background {
                                            Capsule()
                                                .fill(theme.theme.primary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 32.5)
                            }
                            .frame(maxWidth: .infinity, maxHeight: 150, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200, alignment: .topLeading)
                        .padding(.horizontal)
                        VStack(spacing: 15) {
                            LazyVStack {
                                ForEach(vmAlbum.albumDetails?.songs ?? [], id: \.id) { song in
                                    SongItemView(song: song, isLoading: $vmAlbum.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                                        .frame(height: 55)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if let albumArtists = vmAlbum.albumDetails?.allArtists, (!albumArtists.isEmpty) {
                            VStack(spacing: 15) {
                                Text("Album Most Artists 🎙️")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 45)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 20) {
                                        ForEach(albumArtists, id: \.id) { artist in
                                            NavigationLink {
                                                ArtistDetailsView(artist: artist)
                                            } label: {
                                                ArtistItemView(artist: artist, isLoading: $vmAlbum.isLoading, action: { artistMenuActionPerform($0, $1) })
                                                    .frame(width: 150, height: 190)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                BackButtonHeaderView(backType: .albums) {
                    dismiss()
                }
            }
            .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
            .task {
                await vmAlbum.getAlbumDetails(album.id)
            }
            .onAppear {
                showImage = false
                withAnimation(.easeOut(duration: 0.5)) {
                    showImage = true
                }
            }
            .onDisappear {
                showImage = false
            }
            .trackDetailScreenLifecycle()
#endif
        }
        .navigationBarBackButtonHidden()
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

#Preview {
    AlbumDetailsView(album: album1)
}

let album1 = AlbumModel(
    id: "38682222",
    name: "Bhediya",
    description: "",
    url: "https://www.jiosaavn.com/album/bhediya/wSM2AOubajk_",
    year: 2023,
    type: "album",
    playCount: nil,
    language: "Hindi",
    explicitContent: false,
    songCount: nil,
    artists: .init(
        primary: [
            .init(
                id: "2880232",
                name: "Shashwat Sachdev",
                role: "primary_artists",
                image: [
                    .init(
                        quality: .high,
                        url: "https://c.saavncdn.com/artists/Shashwat_Sachdev_000_20221011114409_500x500.jpg"
                    )
                ],
                type: "artist",
                url: "https://www.jiosaavn.com/artist/shashwat-sachdev-songs/uw2,xHu36Uo_"
            )
        ],
        featured: [
            
        ],
        all: [
            .init(
                id: "2880232",
                name: "Shashwat Sachdev",
                role: "primary_artists",
                image: [
                    .init(
                        quality: .high,
                        url: "https://c.saavncdn.com/artists/Shashwat_Sachdev_000_20221011114409_500x500.jpg"
                    )
                ],
                type: "artist",
                url: "https://www.jiosaavn.com/artist/shashwat-sachdev-songs/uw2,xHu36Uo_"
            )
        ]
    ),
    image: [
        ImageQuality(
            quality: .high,
            url: "https://c.saavncdn.com/editorial/ArijitSinghSadSongsHindi_20240226083401_500x500.jpg"
        )
    ]
)
