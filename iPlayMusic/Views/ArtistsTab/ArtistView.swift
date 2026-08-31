//
//  ArtistView.swift
//  iPlayMusic
//
//  Created by Shiv on 12/07/26.
//

import SwiftUI
import SkeletonUI

struct ArtistView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var vmNewRelease: NewReleaseViewModel = .shared
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmArtist: ArtistViewModel = .init()
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    // Adaptive columns: Minimum width 140pt - window resize par auto 3, 4, 5+ columns banenge
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
                if ((!vmArtist.artists.isEmpty) || (!vmNewRelease.newArtists.isEmpty)) {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            if vmArtist.artists.isEmpty {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmNewRelease.newArtists.enumerated()), id: \.element.id) { index, newArtist in
                                        NavigationLink {
                                            ArtistDetailsView(artist: newArtist)
                                        } label: {
                                            ArtistItemView(artist: newArtist, isLoading: $vmNewRelease.isLoading, action: { artistMenuActionPerform($0, $1) })
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmArtist.artists.enumerated()), id: \.element.id) { index, artist in
                                        NavigationLink {
                                            ArtistDetailsView(artist: artist)
                                        } label: {
                                            ArtistItemView(artist: artist, isLoading: $vmArtist.isLoading, action: { artistMenuActionPerform($0, $1) })
                                                .onAppear {
                                                    if index == vmArtist.artists.count - 3 {
                                                        Task { await vmArtist.loadMoreArtists() }
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
                    EmptyDataView(icon: "music.microphone", title: "No Artist Found", subTitle: "Search for a artists to start listening.")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.artists] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await vmArtist.searchArtists(query: newValue)
                }
            }
#endif
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

// MARK: - Responsive Artist Item View
enum ArtistItemMenuTypes: String, CaseIterable {
    case play, like
    
    var title: String {
        switch self {
        case .play: return "Play"
        case .like: return "Like"
        }
    }
}

struct ArtistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let artist: ArtistModel
    @Binding var isLoading: Bool
    let action: ((ArtistItemMenuTypes, ArtistModel) -> Void)
    @State private var isHover: Bool = false
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            RoundedRectangleWebImageView(url: URL(string: artist.thumbnailURL ?? ""), thumbnail: "music.microphone", radius: 10)
            .aspectRatio(1, contentMode: .fit)
            .skeleton(active: isLoading)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .bottom) {
                if isHover {
                    HStack {
                        Button {
                            action(.play, artist)
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
                            action(.like, artist)
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
            
            // MARK: - Artist Details
            VStack(alignment: .leading, spacing: 3) {
                Text(artist.name ?? "Unknown Artist")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
                    .skeleton(active: isLoading)
                
                Text("Role: \(artist.role ?? "Unknown") • Type: \(artist.type ?? "Unknown")")
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
        .onAppear {
            isLiked = vmArtistRealm.isArtistLiked(artistId: artist.id)
        }
    }
}

struct CircleArtistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmArtistRealm: ArtistRealmViewModel = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let artist: ArtistModel
    @Binding var isLoading: Bool
    let action: ((ArtistItemMenuTypes, ArtistModel) -> Void)
    @State private var isHover: Bool = false
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            CircleWebImageView(url: URL(string: artist.thumbnailURL ?? ""), thumbnail: "music.microphone")
            .aspectRatio(1, contentMode: .fit)
            .skeleton(active: isLoading)
            .clipShape(Circle())
            // MARK: - Artist Details
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(artist.name ?? "Unknown Artist")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .lineLimit(1)
                        .skeleton(active: isLoading)
                    
                    Text("Role: \(artist.role ?? "Unknown") • Type: \(artist.type ?? "Unknown")")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(theme.subText(isDark: isDark))
                        .lineLimit(1)
                        .skeleton(active: isLoading)
                }
                if isHover {
                    Button {
                        isLiked.toggle()
                        action(.like, artist)
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
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Circle())
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isHover = hover
            }
        }
        .onAppear {
            isLiked = vmArtistRealm.isArtistLiked(artistId: artist.id)
        }
    }
}

#Preview {
    ArtistView()
}
