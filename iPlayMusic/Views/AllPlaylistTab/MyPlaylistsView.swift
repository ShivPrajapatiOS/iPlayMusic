//
//  MyPlaylistsView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/08/26.
//

import SwiftUI
import RealmSwift
import Realm
import SkeletonUI

struct MyPlaylistsView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmMyPlaylist: MyPlaylistRealmViewModel = .init()
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @ObservedResults(MyPlaylistRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration(), where: { !$0.isDeleted }, sortDescriptor: SortDescriptor(keyPath: "createAt", ascending: false)) var myPlaylists: Results<MyPlaylistRealmModel>
    
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
                    ForEach(myPlaylists, id: \._id) { myPlaylist in
                        NavigationLink {
                            MyPlaylistDetailsView(myPlaylist: myPlaylist)
                        } label: {
                            MyPlaylistItemView(myPlaylist: myPlaylist, isLoading: $vmMyPlaylist.isLoading)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: appState.searchTextByTab[.myPlaylists] ?? "") { _, newValue in
                guard !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                print(newValue)
            }
#endif
        }
    }
}

struct MyPlaylistItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let myPlaylist: MyPlaylistRealmModel
    @Binding var isLoading: Bool
    @State private var isHover: Bool = false
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Responsive Image Container
            RoundedRectangleDataImageView(data: myPlaylist.imageData, thumbnail: "music.microphone", radius: 10)
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
                Text(myPlaylist.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
                    .skeleton(active: isLoading)
                
                Text("• Type: Playlist")
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
    MyPlaylistsView()
}
