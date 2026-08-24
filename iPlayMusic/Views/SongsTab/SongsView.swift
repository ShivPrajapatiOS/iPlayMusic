//
//  SongsView.swift
//  iPlayMusic
//
//  Created by Shiv on 18/07/26.
//

import SwiftUI
import SkeletonUI

struct SongsView: View {
    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject var vmNewRelease: NewReleaseViewModel
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmSong: SongViewModel = .init()
    @StateObject private var vmSuggestionSong: SongSuggestionViewModel = .init()
    @StateObject private var vmSongRealm: SongRealmViewModel = .init()

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                theme.background(isDark: isDark).ignoresSafeArea()
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack {
                        ForEach(0...20, id: \.self) { song in
                            SongItemView(song: song1, isLoading: $vmSong.isLoading)
                                .frame(height: 55)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ZStack {
                if ((!vmSong.songs.isEmpty) || (!vmNewRelease.newSongs.isEmpty)) {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            if vmSong.songs.isEmpty {
                                LazyVStack {
                                    Text("New Release")
                                        .font(.system(size: 15, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(height: 45)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    ForEach(vmNewRelease.newSongs, id: \.id) { newSong in
                                        SongItemView(song: newSong, isLoading: $vmNewRelease.isLoading, menuAction: { songMenuActionPerform($0, vmSongRealm.mapToRealmSong(from: $1)) })
                                            .frame(height: 55)
                                            .onTapGesture {
                                                Task {
                                                    await vmSuggestionSong.getSuggestion(songId: newSong.id)
                                                }
                                            }
                                    }
                                }
                            } else {
                                LazyVStack {
                                    ForEach(Array(vmSong.songs.enumerated()), id: \.element.id) { index, song in
                                        SongItemView(song: song, isLoading: $vmSong.isLoading, menuAction: { songMenuActionPerform($0, vmSongRealm.mapToRealmSong(from: $1)) })
                                            .frame(height: 55)
                                            .onAppear {
                                                if index == vmSong.songs.count - 3 {
                                                    Task { await vmSong.loadMoreSongs() }
                                                }
                                            }
                                            .onTapGesture {
                                                Task {
                                                    await vmSuggestionSong.getSuggestion(songId: song.id)
                                                }
                                            }
                                    }
                                    if vmSong.isLoadingMore {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                        .padding(.horizontal)
                    }
                } else {
                    VStack {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 55, weight: .light))
                            .foregroundStyle(theme.subText(isDark: isDark))
                            .frame(width: 100, height: 100)
                            .background {
                                Circle()
                                    .fill(theme.secondaryCard(isDark: isDark))
                            }
                        
                        VStack(spacing: 6) {
                            Text("No Songs Found")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.text(isDark: isDark))
                            
                            Text("Search for a song to start listening.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(theme.subText(isDark: isDark))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.songs] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await vmSong.searchSongs(query: newValue)
                }
            }
#endif
        }
    }
    
    private func songMenuActionPerform(_ type: SongMenuActionType, _ song: SongRealmModel) {
        switch type {
        case .play:
            print("Play")
        case .addToMyplaylist:
            print("Add To My Playlist")
        case .addToQueue:
            print("Add To Queue")
        case .like:
            print("Like")
        case .download:
            print("Download")
        }
    }
}


// MARK: - SongItemView
enum SongMenuActionType: String, CaseIterable {
    case play, addToMyplaylist, addToQueue, like, download
}
struct SongItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let song: SongModel
    @Binding var isLoading: Bool
    let menuAction: ((SongMenuActionType, SongModel) -> Void)
        
    var body: some View {
#if os(macOS)
        HStack(spacing: 12) {
            RoundedRectangleWebImageView(url: URL(string: song.thumbnailURL ?? ""))
                .frame(width: 40, height: 40)
                .skeleton(active: isLoading)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(song.name ?? "Unknown") \(song.id)")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .skeleton(active: isLoading)
                Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                    .font(.system(size: 11, weight: .light, design: .default))
                    .foregroundStyle(theme.subText(isDark: isDark))
                    .skeleton(active: isLoading)
            }
            .lineLimit(1)
            
            Spacer(minLength: 10)
            HStack {
                Button {
                    menuAction(.download, song)
                } label: {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .frame(width: 30, height: 30)
                        .help("Download")
                }
                Button {
                    menuAction(.like, song)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(.pink)
                        .frame(width: 30, height: 30)
                        .help("Favorite")
                }
            }
            .buttonStyle(.plain)

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
#else
        SwipeView {
            HStack(spacing: 12) {
                RoundedRectangleWebImageView(url: URL(string: song.thumbnailURL ?? ""))
                    .frame(width: 40, height: 40)
                    .skeleton(active: isLoading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name ?? "Unknown")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .skeleton(active: isLoading)
                    Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                        .font(.system(size: 11, weight: .light, design: .default))
                        .foregroundStyle(theme.subText(isDark: isDark))
                        .skeleton(active: isLoading)
                }
                .lineLimit(1)
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
        } trailingActions: { context in
            SwipeAction {
                print("Like")
                context.state.wrappedValue = .closed
            } label: { _ in
                Image(systemName: "heart")
                    .font(.system(size: 25, weight: .light, design: .default))
                    .foregroundStyle(Color.pink)
            } background: { _ in
                Capsule()
                    .fill(theme.secondaryCard(isDark: isDark))
                    .overlay {
                        Capsule()
                            .stroke(theme.secondaryCard(isDark: isDark), lineWidth: 1)
                    }
            }
        }
        .swipeMinimumDistance(25)
        .swipeActionsStyle(.mask)
        .swipeEnabled(true )
#endif
    }
}

#Preview {
//    SongsView()
    SongItemView(song: song1, isLoading: .constant(false), menuAction: { _, _ in })
}


let song1 = SongModel(
    id: "YiVML4Zo",
    name: "Gehra Hua (From &quot;Dhurandhar&quot;)",
    type: "song",
    year: "2025",
    releaseDate: nil,
    duration: 362,
    label: "SaReGaMA India Ltd",
    explicitContent: false,
    playCount: nil,
    language: "hindi",
    hasLyrics: true,
    lyricsId: nil,
    url: "https://www.jiosaavn.com/song/gehra-hua-from-dhurandhar/KQE9fDgEbVw",
    copyright: "℗ 2025 Saregama India Ltd",
    album: .init(
        id: "70160165",
        name: "Gehra Hua (From &quot;Dhurandhar&quot;)",
        url: "https://www.jiosaavn.com/album/gehra-hua-from-dhurandhar/UVZblPajPVA_"
    ),
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
        .init(
            quality: .high,
            url: "https://c.saavncdn.com/450/Gehra-Hua-From-Dhurandhar-Hindi-2025-20251205154217-500x500.jpg"
        )
    ],
    downloadUrl: [
        .init(
            quality: .kbps12,
            url: "https://aac.saavncdn.com/450/f467e05e2825cec2203546333e0d0550_12.mp4"
        ),
        .init(
            quality: .kbps48,
            url: "https://aac.saavncdn.com/450/f467e05e2825cec2203546333e0d0550_48.mp4"
        ),
        .init(
            quality: .kbps96,
            url: "https://aac.saavncdn.com/450/f467e05e2825cec2203546333e0d0550_96.mp4"
        ),
        .init(
            quality: .kbps160,
            url: "https://aac.saavncdn.com/450/f467e05e2825cec2203546333e0d0550_160.mp4"
        ),
        .init(
            quality: .kbps320,
            url: "https://aac.saavncdn.com/450/f467e05e2825cec2203546333e0d0550_320.mp4"
        )
    ]
)
