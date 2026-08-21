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
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmArtist: ArtistViewModel = .init()
    
    var isDark: Bool {
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
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(Array(vmArtist.artists.enumerated()), id: \.element.id) { index, artist in
                        NavigationLink {
                            ArtistDetailsView(vmArtist: vmArtist, artist: .constant(artist))
                        } label: {
                            ArtistItemView(artist: artist, isLoading: $vmArtist.isLoading)
                                .onAppear {
                                    if index == vmArtist.artists.count - 3 {
                                        Task { await vmArtist.loadMoreArtists() }
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
            .onChange(of: appState.searchTextByTab[.artists] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                Task {
                    await vmArtist.searchArtists(query: newValue)
                }
            }
#endif
        }
    }
}

// MARK: - Responsive Artist Item View

struct ArtistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let artist: ArtistModel
    @Binding var isLoading: Bool
    
    @State private var isHover: Bool = false
    
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
    }
}

#Preview {
    ArtistView()
}
