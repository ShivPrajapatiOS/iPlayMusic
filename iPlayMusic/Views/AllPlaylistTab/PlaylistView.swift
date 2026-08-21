//
//  PlaylistView.swift
//  iPlayMusic
//
//  Created by Shiv on 21/07/26.
//

import SwiftUI
import SkeletonUI

struct PlaylistView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmPlaylist: PlaylistViewModel = .init()
    
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    // Adaptive columns: Minimum 140pt width par auto-adjust hone waale columns
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)]
    }
    
    var body: some View {
        NavigationStack {
#if !os(macOS)
            ZStack {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(Array(vmPlaylist.playlists.enumerated()), id: \.element.id) { index, playlist in
                        NavigationLink {
                            PlaylistDetailsView(vmPlaylist: vmPlaylist, playlist: playlist)
                        } label: {
                            PlaylistItemView(playlist: playlist, isLoading: $vmPlaylist.isLoading)
                                .onAppear {
                                    if index == vmPlaylist.playlists.count - 3 {
                                        Task { await vmPlaylist.loadMorePlaylists() }
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.playlists] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await vmPlaylist.searchPlaylists(query: newValue)
                }
            }
#endif
        }
    }
}

// MARK: - Responsive Playlist Item View

struct PlaylistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let playlist: PlaylistModel
    @Binding var isLoading: Bool
    @State private var isHover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            RoundedRectangleWebImageView(url: URL(string: playlist.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 10)
            .aspectRatio(1, contentMode: .fit)
            .skeleton(active: isLoading)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) {
                if isHover {
                    HStack {
                        Button {
                            print("Play")
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 32, height: 32)
                                .foregroundStyle(Color.white)
                                .background(Capsule().fill(theme.theme.accent))
                        }
                        
                        Spacer(minLength: 12)
                        
                        Button {
                            print("like")
                        } label: {
                            Image(systemName: "heart.fill")
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
                
                Text("• Type: \(playlist.type ?? "Unknown")")
                    .font(.system(size: 11, weight: .regular))
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
