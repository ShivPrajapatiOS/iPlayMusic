//
//  AlbumView.swift
//  iPlayMusic
//
//  Created by Shiv on 20/07/26.
//

import SwiftUI
import SkeletonUI

struct AlbumView: View {
    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject var vmNewRelease: NewReleaseViewModel
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmAlbum: AlbumViewModel = .init()
    
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    // Adaptive columns: Minimum width 140pt - window resize hone par auto columns calculate honge
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
            ZStack {
                if ((!vmAlbum.albums.isEmpty) || (!vmNewRelease.newAlbums.isEmpty)) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            if vmAlbum.albums.isEmpty {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmNewRelease.newAlbums.enumerated()), id: \.element.id) { index, newAlbum in
                                        NavigationLink {
                                            AlbumDetailsView(vmAlbum: vmAlbum, album: newAlbum)
                                        } label: {
                                            AlbumItemView(album: newAlbum, isLoading: $vmNewRelease.isLoading)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmAlbum.albums.enumerated()), id: \.element.id) { index, album in
                                        NavigationLink {
                                            AlbumDetailsView(vmAlbum: vmAlbum, album: album)
                                        } label: {
                                            AlbumItemView(album: album, isLoading: $vmAlbum.isLoading)
                                                .onAppear {
                                                    if index == vmAlbum.albums.count - 3 {
                                                        Task { await vmAlbum.loadMoreAlbums() }
                                                    }
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
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
                            Text("No Album Found")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(theme.text(isDark: isDark))
                            
                            Text("Search for a album to start listening.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(theme.subText(isDark: isDark))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.albums] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await vmAlbum.searchAlbums(query: newValue)
                }
            }
#endif
        }
    }
}

// MARK: - Responsive Album Item View

struct AlbumItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let album: AlbumModel
    @Binding var isLoading: Bool
    @State private var isHover: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            RoundedRectangleWebImageView(
                url: URL(string: album.thumbnailURL ?? ""),
                thumbnail: "music.microphone",
                radius: 10
            )
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
            
            // MARK: - Album Details
            VStack(alignment: .leading, spacing: 3) {
                Text(album.name ?? "Unknown Album")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
                    .skeleton(active: isLoading)
                
                Text("Type: \(album.type ?? "Unknown")")
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
    AlbumView()
        .environmentObject(NewReleaseViewModel())
}
