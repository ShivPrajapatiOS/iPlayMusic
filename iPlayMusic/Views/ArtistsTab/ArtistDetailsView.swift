//
//  ArtistsDetailsView.swift
//  iPlayMusic
//
//  Created by Shiv on 15/07/26.
//

import SwiftUI
import Combine
import SkeletonUI

struct ArtistDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmArtist: ArtistViewModel = .init()
    @StateObject private var vmPlaylist: PlaylistViewModel = .init()
    @StateObject private var vmAlbum: AlbumViewModel = .init()
    @ObservedObject var vmSongRealm: SongRealmViewModel = .shared
    @ObservedObject var vmAlbumRealm: AlbumRealmViewModel = .shared
    @ObservedObject var vmPlaylistRealm: PlaylistRealmViewModel = .shared
    
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var showImage = false
    
    
    let artist: ArtistModel
        
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ZStack {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        HStack(spacing: 25) {
                            RoundedRectangleWebImageView(url: URL(string: vmArtist.artistInfo?.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 15)
                                .frame(width: 200, height: 200)
                                .skeleton(active: vmArtist.isLoading)
                                .opacity(showImage ? 1 : 0)
                                .scaleEffect(showImage ? 1 : 0.9) // Optional
                                .animation(.easeOut(duration: 0.5), value: showImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(vmArtist.artistInfo?.name ?? "Unknown")
                                    .font(.system(size: 25, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                    .skeleton(active: vmArtist.isLoading)
                                Text(vmArtist.artistInfo?.type ?? "Unknown")
                                    .font(.system(size: 25, weight: .regular, design: .default))
                                    .foregroundStyle(theme.theme.accent)
                                    .skeleton(active: vmArtist.isLoading)
                                Text(vmArtist.artistInfo?.bio?.first?.text ?? "N|A")
                                    .font(.system(size: 12, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .lineLimit(3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                    .skeleton(active: vmArtist.isLoading)
                                    .help(vmArtist.artistInfo?.bio?.first?.text ?? "")
                                HStack {
                                    Button {
                                        guard let artistPlayback = vmArtist.artistInfo else { return }
                                        PlayerManager.shared.setupPlay(
                                            songs: artistPlayback.topSongs ?? [],
                                            playIndex: 0,
                                            source: .artist(artistPlayback)
                                        )
                                    } label: {
                                        HStack {
                                            Image(systemName: "play.fill")
                                            Text("Play")
                                        }
                                        .frame(maxHeight: .infinity)
                                        .frame(width: 135)
                                        .foregroundStyle(theme.text(isDark: isDark))
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
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Top Songs")
                                        .font(.system(size: 15, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                    Spacer()
                                    Button {
                                        print("More top songs")
                                    } label: {
                                        Text("More Top Songs")
                                            .font(.system(size: 11, weight: .regular, design: .default))
                                            .foregroundStyle(theme.theme.accent)
                                            .frame(height: 30)
                                            .padding(.horizontal, 10)
                                            .background {
                                                RoundedRectangle(cornerRadius: 7)
                                                    .fill(Color("#FFFFFF").opacity(0.0001))
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 45)
                                LazyVStack {
                                    ForEach(Array((vmArtist.artistInfo?.topSongs ?? []).enumerated()), id: \.element.id) { index, song in
                                        SongItemView(song: song, isLoading: $vmArtist.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                                            .frame(height: 55)
                                            .onTapGesture {
                                                guard let artistPlayback = vmArtist.artistInfo else { return }
                                                PlayerManager.shared.setupPlay(
                                                    songs: artistPlayback.topSongs ?? [],
                                                    playIndex: index,
                                                    source: .artist(artistPlayback)
                                                )
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            if ((!vmPlaylist.isLoading) && (!vmPlaylist.playlists.isEmpty)) {
                                VStack(spacing: 0) {
                                    Text("Just For You \(artist.name ?? "Unknown")")
                                        .font(.system(size: 15, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(height: 45)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 12) {
                                            ForEach(vmPlaylist.playlists, id: \.id) { playlist in
                                                NavigationLink {
                                                    PlaylistDetailsView(playlist: playlist)
                                                } label: {
                                                    PlaylistItemView(playlist: playlist, isLoading: $vmPlaylist.isLoading, action: { playlistMenuActionPerform($0, $1) })
                                                    .frame(width: 150, height: 190)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            if ((!vmAlbum.isLoading) && (!vmAlbum.albums.isEmpty)) {
                                VStack(spacing: 0) {
                                    Text("Just For You \(artist.name ?? "Unknown") Albums")
                                        .font(.system(size: 15, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(height: 45)
                                        .padding(.horizontal)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 12) {
                                            ForEach(vmAlbum.albums, id: \.id) { album in
                                                NavigationLink {
                                                    AlbumDetailsView(album: album)
                                                } label: {
                                                    AlbumItemView(album: album, isLoading: $vmAlbum.isLoading, action: { albumMenuActionPerform($0, $1) })
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                BackButtonHeaderView(backType: .artists) {
                    dismiss()
                }
            }
            .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
            .task(priority: .userInitiated) {
                await vmArtist.loadArtist(id: artist.id)
            }
            .task(priority: .utility) {
                guard let artistName = artist.name else { return }
                async let playlists: () = vmPlaylist.searchPlaylists(query: artistName)
                async let albums: () = vmAlbum.searchAlbums(query: artistName)
                _ = await (playlists, albums)
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
}

#Preview {
    ArtistDetailsView(artist: artist1)
}

let artist1 = ArtistModel(
    id: "459320",
    name: "Arijit Singh",
    role: "singer",
    image: [
        ImageQuality(
            quality: .high,
            url: "https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg"
        )
    ],
    type: "artist",
    url: "https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg"
)


let defaultArtistDetails = ArtistDetailsModel(
    id: "38682222",
    name: "Arijit Singh",
    url: "https://www.jiosaavn.com/artist/arijit-singh/LlRWpHzy3Hk_",
    type: "artist",
    followerCount: 104712075,
    fanCount: "10890113",
    isVerified: true,
    dominantLanguage: "hindi",
    dominantType: "singer", bio: [
        .init(
            text: "Arijit Singh, is an Indian playback singer. He was one of top six contestants in reality-singing series, Fame Gurukul in 2005 and became an assistant to music director Pritam.Known for his soulful voice that reverberates with romantic songs, Arijit Singh is setting new trends in the music industry, by stirring up unforgetable notes for the young hearts. Arijit was born in Murshidabad, Jiaganj, West Bengal, India on 25th April, 1987. He got married to Koel(in Jan 2014)and the couple lives in Mumbai.", sequence: 1,
            title: "Introduction"
        )
    ],
    dob: "25-04-1987",
    fb: nil,
    twitter: nil,
    wiki: "http://en.wikipedia.org/wiki/Arijit_Singh",
    availableLanguages: [
        "hindi",
        "bengali",
        "english",
        "telugu",
        "unknown",
        "punjabi",
        "tamil",
        "marathi",
        "kannada",
        "french"
    ],
    isRadioPresent: true,
    image: [
        .init(
            quality: .high,
            url: "https://c.saavncdn.com/artists/Arijit_Singh_004_20241118063717_500x500.jpg"
        )
    ],
    topSongs: [
        .init(
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
    ]
)
