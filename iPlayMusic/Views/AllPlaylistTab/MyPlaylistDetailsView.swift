//
//  MyPlaylistDetailsView.swift
//  iPlayMusic
//
//  Created by Shiv on 08/09/26.
//

import SwiftUI
import RealmSwift
import Realm
import SkeletonUI

struct MyPlaylistDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    @StateObject private var player: PlayerManager = .shared
    @StateObject private var vmMyPlaylist: MyPlaylistRealmViewModel = .init()
    @StateObject private var network: NetworkManager = .init()
    
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var showAddSongSheet: Bool = false
    @State private var isShowPlaylistEdit: Bool = false
    @State private var isShowDeleteAlert: Bool = false
    @State private var deleteMyPlaylist: MyPlaylistRealmModel? = nil
    
    @State private var showImage = false
    
    
    let myPlaylist: MyPlaylistRealmModel
    
    @ObservedResults(SongRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration()) var songs: Results<SongRealmModel>
    
    init(myPlaylist: MyPlaylistRealmModel) {
        self.myPlaylist = myPlaylist
        self._songs = ObservedResults(SongRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration(), filter: NSPredicate(format: "playlist_id == %@ AND isDeleted == false", myPlaylist._id.stringValue as CVarArg), sortDescriptor: SortDescriptor(keyPath: "createAt", ascending: true))
    }
    
    private var songObjs: [SongModel] {
        songs.compactMap { convertSongRealmToSongModel(song: $0) }
    }
        
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
                            RoundedRectangleDataImageView(data: myPlaylist.imageData, thumbnail: "music.microphone", radius: 10)
                                .frame(width: 200, height: 200)
                                .skeleton(active: vmMyPlaylist.isLoading)
                                .opacity(showImage ? 1 : 0)
                                .scaleEffect(showImage ? 1 : 0.9)
                                .animation(.easeOut(duration: 0.5), value: showImage)
                            VStack(alignment: .leading, spacing: 8) {
                                Text(myPlaylist.name)
                                    .font(.system(size: 25, weight: .semibold, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                    .skeleton(active: vmMyPlaylist.isLoading)
                                Text("Unknown Type")
                                    .font(.system(size: 25, weight: .regular, design: .default))
                                    .foregroundStyle(theme.theme.accent)
                                    .skeleton(active: vmMyPlaylist.isLoading)
                                Spacer()
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
                                    Spacer()
                                    Button {
                                        Task {
                                            do {
                                                let likePlaylist = try await vmMyPlaylist.likeUnlikePlaylist(playlistId: myPlaylist._id, isLike: !myPlaylist.isLike)
                                                vmMyPlaylist.errorMessage = nil
                                                let tableReference = try await FirebaseSyncManager.shared.updateMyPlaylistSync(likePlaylist)
                                                print("this Object isSynced: \(tableReference)")
                                                try await FirebaseSyncManager.shared.isSync(object: likePlaylist)
                                            } catch {
                                                vmMyPlaylist.errorMessage = error.localizedDescription
                                            }
                                        }
                                    } label: {
                                        Image(systemName: myPlaylist.isLike ? "heart.fill" : "heart")
                                            .font(.system(size: 20, weight: .light, design: .default))
                                            .foregroundStyle(LinearGradient(colors: myPlaylist.isLike ? [.red, .pink] : [theme.subText(isDark: isDark).opacity(0.25)], startPoint: .bottomLeading, endPoint: .topTrailing))
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
                                ForEach(Array(songObjs.enumerated()), id: \.element.id) { index, song in
                                    SongItemView(song: song, isLoading: $vmSongRealm.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                                        .frame(height: 55)
                                        .onTapGesture {
                                            player.setupPlay(songs: songObjs, playIndex: index)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                BackButtonHeaderView(backType: .myPlaylists) { menuActionPerform($0) } backAction: {
                    dismiss()
                }
            }
            .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
            .sheet(isPresented: $isShowPlaylistEdit) {
                CreatePlaylistView(vmMyPlaylist: vmMyPlaylist, showCreatePlaylist: $isShowPlaylistEdit)
            }
            .sheet(isPresented: $showAddSongSheet, content: {
                SelectSongSheetView(onSongsSelected: { selectedSongs in
                    Task {
                        do {
                            try await SongRealmViewModel.shared.addSelectedSongsToPlaylist(selectedSongs, playlistId: myPlaylist._id)
                        } catch {
                            vmMyPlaylist.errorMessage = error.localizedDescription
                        }
                    }
                })
                .frame(width: 475, height: 475)
            })
            .alert("Delete Playlist?", isPresented: $isShowDeleteAlert, presenting: deleteMyPlaylist) { deleteMyPlaylist in
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            if network.isConnected {
                                try await vmMyPlaylist.deleteDeletePlaylistById(playlistId: deleteMyPlaylist._id)
                                dismiss()
                            } else {
                                try await vmMyPlaylist.softDeletePlaylistById(playlistId: deleteMyPlaylist._id)
                                dismiss()
                            }
                        } catch {
                            vmMyPlaylist.errorMessage = error.localizedDescription
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    self.deleteMyPlaylist = nil
                }
            } message: { deleteMyPlaylist in
                Text("Are you sure you want to delete '\(deleteMyPlaylist.name)'? This action cannot be undone")
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
    
    private func convertSongRealmToSongModel(song: SongRealmModel) -> SongModel? {
        do {
            return try song.toSongModel()
        } catch {
            return nil
        }
    }
    
    private func menuActionPerform(_ type: MyPlaylistMenuType) {
        switch type {
        case .edit:
            vmMyPlaylist.isUpdatePlaylist = myPlaylist
            isShowPlaylistEdit.toggle()
        case .addSong:
            showAddSongSheet = true
        case .addToQueue:
            print("addToQueue")
        case .delete:
            deleteMyPlaylist = myPlaylist
            isShowDeleteAlert = true
        }
    }
    
    private func songMenuActionPerform(_ type: SongMenuActionType?, _ song: SongModel) {
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
        default: break;
        }
    }
}


struct MySongItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let song: SongRealmModel
    @Binding var isLoading: Bool
        
    var body: some View {
#if os(macOS)
        HStack(spacing: 12) {
            RoundedRectangleWebImageView(url: URL(string: song.image?.url ?? ""))
                .frame(width: 40, height: 40)
                .skeleton(active: isLoading)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(song.name ?? "Unknown") \(song.id)")
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .skeleton(active: isLoading)
//                Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
//                    .font(.system(size: 11, weight: .light, design: .default))
//                    .foregroundStyle(theme.subText(isDark: isDark))
//                    .skeleton(active: isLoading)
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
#else
        SwipeView {
            HStack(spacing: 12) {
                RoundedRectangleWebImageView(url: URL(string: song.image?.url ?? ""))
                    .frame(width: 40, height: 40)
                    .skeleton(active: isLoading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name ?? "Unknown")
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .skeleton(active: isLoading)
//                    Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
//                        .font(.system(size: 11, weight: .light, design: .default))
//                        .foregroundStyle(theme.subText(isDark: isDark))
//                        .skeleton(active: isLoading)
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


private func defaultMyPlaylistObject() -> MyPlaylistRealmModel {
    let myPlaylist = MyPlaylistRealmModel()
    myPlaylist.name = "Default"
    myPlaylist.desc = "Default Playlist"
    return myPlaylist
}

#Preview {
    MyPlaylistDetailsView(myPlaylist: defaultMyPlaylistObject())
}
