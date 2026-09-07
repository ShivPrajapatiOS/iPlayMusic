//
//  QueueItemView.swift
//  iPlayMusic
//
//  Created by Shiv on 17/07/26.
//

import SwiftUI
import VLCKit

struct QueueItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let song: SongModel
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangleWebImageView(url: URL(string: song.thumbnailURL ?? ""), radius: 5)
                .frame(width: 40, height: 40)
                .overlay {
                    if player.state == .playing && player.currentSong?.id == song.id {
                        LineVisualizerView()
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(song.name ?? "Unknown")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                    .font(.system(size: 11, weight: .light, design: .default))
                    .foregroundStyle(theme.subText(isDark: isDark))
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 5).fill(theme.secondaryCard(isDark: isDark).opacity(0.00001)))
    }
}

#Preview {
    QueueItemView(song: song1)
}
