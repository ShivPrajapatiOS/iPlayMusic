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
    
    
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var showImage = false
    
    
    @ObservedObject var vmAlbum: AlbumViewModel
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
                                    SongItemView(song: song, isLoading: $vmAlbum.isLoading, menuAction: { _, _ in })
                                        .frame(height: 55)
                                }
                            }
                            .padding(.horizontal)
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
                appState.isDetailScreenActive = true
                showImage = false
                withAnimation(.easeOut(duration: 0.5)) {
                    showImage = true
                }
            }
            .onDisappear {
                appState.isDetailScreenActive = false
                showImage = false
            }
#endif
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    AlbumDetailsView(vmAlbum: .init(), album: album1)
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
