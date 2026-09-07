//
//  QueueListPlayView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI

struct QueueListPlayView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    @StateObject private var player: PlayerManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var isShow: Bool
    
    var body: some View {
        ZStack {
            theme.background(isDark: isDark)
                .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.queueSongsList.enumerated()), id: \.element.id) { (index, song) in
                        QueueItemView(song: song)
                            .frame(height: 50)
                            .overlay(alignment: .bottom, content: {
                                if player.queueSongsList.last?.id != song.id {
                                    theme.border(isDark: isDark).opacity(0.25)
                                        .frame(height: 1)
                                }
                            })
                            .onTapGesture {
                                player.playFromPlaylist(index: index)
                            }
                    }
                }
                .padding(.vertical, isShow ? 12 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
        .containerShape(Rectangle())
    }
}

#Preview {
    QueueListPlayView(isShow: .constant(false))
}
