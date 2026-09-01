//
//  PlaylistView.swift
//  iPlayMusic
//
//  Created by Shiv on 21/07/26.
//

import SwiftUI
import RealmSwift
import Realm
import SkeletonUI

struct PlaylistView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject var vmNewRelease: NewReleaseViewModel = .shared
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmPlaylist: PlaylistViewModel = .init()
    @StateObject private var vmPlaylistRealm: PlaylistRealmViewModel = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    // Adaptive columns: Minimum 140pt width par auto-adjust hone waale columns
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)]
    }
    
    @ObservedResults(PlaylistRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration(), where: { $0.isLike && !$0.isDeleted }, sortDescriptor: SortDescriptor(keyPath: "createAt", ascending: false)) var favoritePlaylists: Results<PlaylistRealmModel>
    
    var body: some View {
        NavigationStack {
#if !os(macOS)
            ZStack {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !vmPlaylist.playlists.isEmpty {
                            LazyVGrid(columns: gridColumns, spacing: 20) {
                                ForEach(Array(vmPlaylist.playlists.enumerated()), id: \.element.id) { index, playlist in
                                    NavigationLink {
                                        PlaylistDetailsView(playlist: playlist)
                                    } label: {
                                        PlaylistItemView(playlist: playlist, isLoading: $vmPlaylist.isLoading, action: { playlistMenuActionPerform($0, $1) })
                                            .onAppear {
                                                if index == vmPlaylist.playlists.count - 3 {
                                                    Task { await vmPlaylist.loadMorePlaylists() }
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            if !vmNewRelease.newPlaylists.isEmpty {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmNewRelease.newPlaylists.enumerated()), id: \.element.id) { index, newPlaylist in
                                        NavigationLink {
                                            PlaylistDetailsView(playlist: newPlaylist)
                                        } label: {
                                            PlaylistItemView(playlist: newPlaylist, isLoading: $vmNewRelease.isLoading, action: { playlistMenuActionPerform($0, $1) })
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            if !favoritePlaylists.isEmpty {
                                VStack {
                                    Text("Favorite Liked 😘")
                                        .font(.system(size: 20, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(height: 45)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    LazyVGrid(columns: gridColumns, spacing: 20) {
                                        ForEach(favoritePlaylists, id: \._id) { favorPlaylist in
                                            if let playlistObj = convertPlaylistRealmToPlaylistModel(playlist: favorPlaylist) {
                                                NavigationLink {
                                                    PlaylistDetailsView(playlist: playlistObj)
                                                } label: {
                                                    PlaylistItemView(playlist: playlistObj, isLoading: .constant(false), action: { playlistMenuActionPerform($0, $1) })
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                
                if vmPlaylist.playlists.isEmpty && vmNewRelease.newPlaylists.isEmpty && favoritePlaylists.isEmpty {
                    EmptyDataView(icon: "music.note.list", title: "No Playlist Found", subTitle: "Search for a playlist to start listening.")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.playlists] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    if !vmPlaylist.playlists.isEmpty {
                        vmPlaylist.playlists.removeAll()
                    }
                    return
                }
                Task {
                    await vmPlaylist.searchPlaylists(query: newValue)
                }
            }
#endif
        }
    }
    
    private func convertPlaylistRealmToPlaylistModel(playlist: PlaylistRealmModel) -> PlaylistModel? {
        do {
            return try playlist.toPlaylistModel()
        } catch {
            return nil
        }
    }
    
    private func playlistMenuActionPerform(_ type: PlaylistItemMenuTypes, _ playlist: PlaylistModel) {
        switch type {
        case .play:
            print("Play")
        case .like:
            Task {
                do {
                    vmPlaylistRealm.isLoading = true
                    let likedPlaylist = try await vmPlaylistRealm.toggleLikePlaylist(playlist: playlist)
                    print(likedPlaylist.toJSON())
                    vmPlaylistRealm.errorMessage = nil
                    vmPlaylistRealm.isLoading = false
                    
                    if likedPlaylist.isLike {
                        // Naya like → Realm me pehli baar tha to addSong, warna updateSong
                        let tableReference = try await FirebaseSyncManager.shared.updatePlaylist(playlist: likedPlaylist)
                        print("this Object isSynced: \(tableReference)")
                    } else {
                        let tableReference = try await FirebaseSyncManager.shared.updatePlaylist(playlist: likedPlaylist)
                        print("this Object isSynced: \(tableReference)")
                    }
                    try await FirebaseSyncManager.shared.isSync(object: likedPlaylist)
                } catch {
                    vmPlaylistRealm.isLoading = false
                    vmPlaylistRealm.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Responsive Playlist Item View

enum PlaylistItemMenuTypes: String, CaseIterable {
    case play, like
    
    var title: String {
        switch self {
        case .play: return "Play"
        case .like: return "Like"
        }
    }
}

struct PlaylistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmPlaylistRealm: PlaylistRealmViewModel = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let playlist: PlaylistModel
    @Binding var isLoading: Bool
    let action: ((PlaylistItemMenuTypes, PlaylistModel) -> Void)
    @State private var isHover: Bool = false
    @State private var isLiked: Bool = false

    // Exact fractions measured from JioSaavn's CDN watermark position
    private let iconXFraction: CGFloat = 0.049
    private let iconYFraction: CGFloat = 0.052
    private let iconSizeFraction: CGFloat = 0.079
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            RoundedRectangleWebImageView(url: URL(string: playlist.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 10)
            .aspectRatio(1, contentMode: .fit)
            .skeleton(active: isLoading)
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
            .overlay(alignment: .bottom) {
                if isHover {
                    HStack {
                        Button {
                            action(.play, playlist)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Color.white)
                                .background(Capsule().fill(theme.theme.accent))
                        }
                        
                        Spacer(minLength: 12)
                        
                        Button {
                            isLiked.toggle()
                            action(.like, playlist)
                        } label: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .light))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .pink],
                                        startPoint: .bottomLeading,
                                        endPoint: .topTrailing
                                    )
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(8)
                    .background(
                        LinearGradient(
                            colors: [.black.opacity(0.6), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            
            // MARK: - Playlist Details
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name ?? "Unknown Playlist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
                    .skeleton(active: isLoading)
                
                HStack {
                    if let sognCount = playlist.songCount {
                        Text("\(sognCount) Songs • ")
                    }
                    Text("Type: \(playlist.type ?? "Unknown")")
                    Spacer()
                }
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(theme.subText(isDark: isDark))
                .lineLimit(1)
                .skeleton(active: isLoading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHover = hover
            }
        }
        .onAppear {
            isLiked = vmPlaylistRealm.isPlaylistLiked(playlistId: playlist.id)
        }
    }
}

#Preview {
    PlaylistView()
}


let playlist1 = PlaylistModel(
    id: "802336660",
    name: "Arijit Singh - Sad Songs - Hindi",
    type: "playlist",
    image: [
        ImageQuality(
            quality: .high,
            url: "https://c.saavncdn.com/editorial/ArijitSinghSadSongsHindi_20240226083401_500x500.jpg")
    ],
    url: "https://www.jiosaavn.com/featured/arijit-singh-sad-songs-hindi/8RkefqkCO1huOxiEGmm6lQ__",
    songCount: 25,
    language: "hindi",
    explicitContent: false
)
