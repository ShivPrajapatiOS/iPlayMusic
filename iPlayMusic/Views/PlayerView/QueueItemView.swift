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
            
            Spacer()
            
            HStack(spacing: 20) {
                Image(systemName: "line.3.horizontal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(theme.theme.accent.opacity(0.25))
                if player.state != .playing && player.currentSong?.id != song.id {
                    Button {
                        if let index = player.queueSongsList.firstIndex(where: { $0.id == song.id }) {
                            player.removeFromQueue(at: index)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .background(RoundedRectangle(cornerRadius: 5).fill(theme.secondaryCard(isDark: isDark).opacity(0.00001)))
    }
}

#Preview {
    QueueItemView(song: song1)
}
