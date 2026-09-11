//
//  PlaylistDetailsView.swift
//  iPlayMusic
//
//  Created by Shiv on 09/08/26.
//

import SwiftUI
import SkeletonUI
import RealmSwift
import Realm

struct PlaylistDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared
    @StateObject private var player: PlayerManager = .shared
    @StateObject var vmPlaylist: PlaylistViewModel = .init()
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var showImage = false    
    
    let playlist: PlaylistModel
    
    private let iconXFraction: CGFloat = 0.049
    private let iconYFraction: CGFloat = 0.052
    private let iconSizeFraction: CGFloat = 0.079
        
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
                            RoundedRectangleWebImageView(url: URL(string: vmPlaylist.detailsPlaylist?.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 15)
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
                                .frame(width: 200, height: 200)
                                .skeleton(active: vmPlaylist.isLoading)
                                .opacity(showImage ? 1 : 0)
                                .scaleEffect(showImage ? 1 : 0.9)
                                .animation(.easeOut(duration: 0.5), value: showImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vmPlaylist.detailsPlaylist?.name ?? "Unknown")
                                    .font(.system(size: 25, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                    .skeleton(active: vmPlaylist.isLoading)
                                Text(vmPlaylist.detailsPlaylist?.type ?? "Unknown")
                                    .font(.system(size: 25, weight: .regular, design: .default))
                                    .foregroundStyle(theme.theme.accent)
                                    .skeleton(active: vmPlaylist.isLoading)
                                Text(vmPlaylist.detailsPlaylist?.firstname ?? "N|A")
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .skeleton(active: vmPlaylist.isLoading)
                                HStack {
                                    Button {
                                        guard let playlistPlayback = vmPlaylist.detailsPlaylist else { return }
                                        PlayerManager.shared.setupPlay(songs: playlistPlayback.songs ?? [], playIndex: 0, source: .playlist(playlistPlayback))
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
                                    Spacer()
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
                                ForEach(Array((vmPlaylist.detailsPlaylist?.songs ?? []).enumerated()), id: \.element.id) { index, song in
                                    SongItemView(song: song, isLoading: $vmPlaylist.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                                        .frame(height: 55)
                                        .onTapGesture {
                                            guard let playlistPlayback = vmPlaylist.detailsPlaylist else { return }
                                            PlayerManager.shared.setupPlay(songs: playlistPlayback.songs ?? [], playIndex: index, source: .playlist(playlistPlayback))
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        if let playlistArtists = vmPlaylist.detailsPlaylist?.allArtists, (!playlistArtists.isEmpty) {
                            VStack(spacing: 15) {
                                Text("Playlist Most Artists 🎙️")
                                    .font(.system(size: 15, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(height: 45)
                                    .padding(.horizontal)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 20) {
                                        ForEach(playlistArtists, id: \.id) { artist in
                                            NavigationLink {
                                                ArtistDetailsView(artist: artist)
                                            } label: {
                                                CircleArtistItemView(artist: artist, isLoading: $vmPlaylist.isLoading, action: { artistMenuActionPerform($0, $1) })
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
                BackButtonHeaderView(backType: .playlists) {
                    dismiss()
                }
            }
            .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
            .task {
                await vmPlaylist.getPlaylistDetails(playlist.id)
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
    
    private func isCurrentlyPlaying(_ playlist: PlaylistDetailsModel) -> Bool {
        if case .playlist(let p) = player.currentPlaybackSource {
            return p.id == playlist.id
        }
        return false
    }
    
    private func songMenuActionPerform(_ type: SongMenuActionType?, _ song: SongModel) {
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
        default: break;
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
    PlaylistDetailsView(vmPlaylist: .init(), playlist: playlist1)
}
