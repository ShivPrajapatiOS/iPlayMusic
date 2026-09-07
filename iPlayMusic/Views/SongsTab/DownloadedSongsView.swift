//
//  DownloadedSongsView.swift
//  iPlayMusic
//
//  Created by Shiv on 07/09/26.
//

import SwiftUI
import RealmSwift
import Realm
import SkeletonUI

struct DownloadedSongsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @StateObject private var vmSongRealm: SongRealmViewModel = .shared
    @StateObject private var player: PlayerManager = .shared
    
    @ObservedResults(SongRealmModel.self, configuration: SharedRealm.getSharedRealmConfiguration(), where: { $0.isDownloaded && !$0.isDeleted }, sortDescriptor: SortDescriptor(keyPath: "createAt", ascending: false)) var favoriteSongs: Results<SongRealmModel>
    
    private var songObjs: [SongModel] {
        favoriteSongs.compactMap { convertSongRealmToSongModel(song: $0) }
    }
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(Array(songObjs.enumerated()), id: \.element.id) { index, newSong in
                        SongItemView(song: newSong, isLoading: $vmSongRealm.isLoading, menuAction: { songMenuActionPerform($0, $1) })
                            .frame(height: 55)
                            .onTapGesture {
                                player.setupPlay(songs: songObjs, playIndex: index)
                            }
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing, content: {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10 ,weight: .light, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .frame(width: 22.5, height: 22.5)
                    .background(Circle().fill(theme.subText(isDark: !isDark)))
            }
            .buttonStyle(.plain)
            .padding()
        })
    }
    
    private func convertSongRealmToSongModel(song: SongRealmModel) -> SongModel? {
        do {
            return try song.toSongModel()
        } catch {
            return nil
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
    DownloadedSongsView()
}
