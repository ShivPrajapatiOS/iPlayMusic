//
//  AlbumView.swift
//  iPlayMusic
//
//  Created by Shiv on 20/07/26.
//

import SwiftUI
import RealmSwift
import Realm
import SkeletonUI

struct AlbumView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var vmNewRelease: NewReleaseViewModel = .shared
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmAlbum: AlbumViewModel = .init()
    @StateObject private var vmalbumRealm: AlbumRealmViewModel = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    // Adaptive columns: Minimum width 140pt - window resize hone par auto columns calculate honge
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)]
    }
    
    @ObservedResults(AlbumRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration(), where: { $0.isLike && !$0.isDeleted }, sortDescriptor: SortDescriptor(keyPath: "createAt", ascending: false)) var favoriteAlbums: Results<AlbumRealmModel>
    
    var body: some View {
        NavigationStack {
#if !os(macOS)
            ZStack {
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            ZStack {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        if !vmAlbum.albums.isEmpty {
                            LazyVGrid(columns: gridColumns, spacing: 20) {
                                ForEach(Array(vmAlbum.albums.enumerated()), id: \.element.id) { index, album in
                                    NavigationLink {
                                        AlbumDetailsView(album: album)
                                    } label: {
                                        AlbumItemView(album: album, isLoading: $vmAlbum.isLoading, action: { albumMenuActionPerform($0, $1) })
                                            .onAppear {
                                                if index == vmAlbum.albums.count - 3 {
                                                    Task { await vmAlbum.loadMoreAlbums() }
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        } else {
                            if !vmNewRelease.newAlbums.isEmpty {
                                LazyVGrid(columns: gridColumns, spacing: 20) {
                                    ForEach(Array(vmNewRelease.newAlbums.enumerated()), id: \.element.id) { index, newAlbum in
                                        NavigationLink {
                                            AlbumDetailsView(album: newAlbum)
                                        } label: {
                                            AlbumItemView(album: newAlbum, isLoading: $vmNewRelease.isLoading, action: { albumMenuActionPerform($0, $1) })
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            if !favoriteAlbums.isEmpty {
                                VStack {
                                    Text("Favorite Albums 😘")
                                        .font(.system(size: 20, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(height: 45)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    LazyVGrid(columns: gridColumns, spacing: 20) {
                                        ForEach(favoriteAlbums, id: \._id) { favorAlbum in
                                            if let albumObj = convertAlbumRealmToAlbumModel(album: favorAlbum) {
                                                NavigationLink {
                                                    AlbumDetailsView(album: albumObj)
                                                } label: {
                                                    AlbumItemView(album: albumObj, isLoading: .constant(false), action: { albumMenuActionPerform($0, $1) })
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
                
                if vmAlbum.albums.isEmpty && vmNewRelease.newAlbums.isEmpty && favoriteAlbums.isEmpty {
                    EmptyDataView(icon: "music.note.square.stack", title: "No Album Found", subTitle: "Search for a album to start listening.")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.albums] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    if !vmAlbum.albums.isEmpty {
                        vmAlbum.albums.removeAll()
                    }
                    return
                }
                Task {
                    await vmAlbum.searchAlbums(query: newValue)
                }
            }
#endif
        }
    }
    
    private func convertAlbumRealmToAlbumModel(album: AlbumRealmModel) -> AlbumModel? {
        do {
            return try album.toAlbumModel()
        } catch {
            print("❌ Album conversion error:", error)
            return nil
        }
    }
    
    private func albumMenuActionPerform(_ type: AlbumItemMenuTypes, _ album: AlbumModel) {
        switch type {
        case .play:
            print("Play")
        case .like:
            Task {
                do {
                    vmalbumRealm.isLoading = true
                    let likedAlbum = try await vmalbumRealm.toggleLikeAlbum(album: album)
                    print(likedAlbum.toJSON())
                    vmalbumRealm.errorMessage = nil
                    vmalbumRealm.isLoading = false
                    
                    if likedAlbum.isLike {
                        let tableReference = try await FirebaseSyncManager.shared.updateAlbum(album: likedAlbum)
                        print("this Object isSynced: \(tableReference)")
                    } else {
                        let tableReference = try await FirebaseSyncManager.shared.updateAlbum(album: likedAlbum)
                        print("this Object isSynced: \(tableReference)")
                    }
                    try await FirebaseSyncManager.shared.isSync(object: likedAlbum)
                } catch {
                    vmalbumRealm.isLoading = false
                    vmalbumRealm.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Responsive Album Item View
enum AlbumItemMenuTypes: String, CaseIterable {
    case play, like
    
    var title: String {
        switch self {
        case .play: return "Play"
        case .like: return "Like"
        }
    }
}

struct AlbumItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmAlbumRealm: AlbumRealmViewModel = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let album: AlbumModel
    @Binding var isLoading: Bool
    let action: ((AlbumItemMenuTypes, AlbumModel) -> Void)
    @State private var isHover: Bool = false
    @State private var isLiked: Bool = false
    
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
                            action(.play, album)
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
                            action(.like, album)
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
            
            // MARK: - Album Details
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name ?? "Unknown Album")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
                    .skeleton(active: isLoading)
                HStack {
                    if let sognCount = album.songCount {
                        Text("\(sognCount) Songs • ")
                    }
                    Text("Type: \(album.type ?? "Unknown")")
                    Spacer()
                }
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
            isLiked = vmAlbumRealm.isAlbumLiked(albumId: album.id)
        }
    }
}

#Preview {
    AlbumView()
}
