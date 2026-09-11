//
//  QueueListPlayView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI
import UniformTypeIdentifiers

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
    
    @State private var dropTargetIndex: Int? = nil
    
    var body: some View {
        ZStack {
            theme.background(isDark: isDark)
                .ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.queueSongsList.enumerated()), id: \.element.id) { (index, song) in
                        QueueItemView(song: song)
                            .frame(height: 50)
                            .onDrag {
                                return NSItemProvider(object: song.id as NSString)
                            }
                            .overlay(alignment: .bottom, content: {
                                if player.queueSongsList.last?.id != song.id {
                                    if dropTargetIndex == index {
                                        Color.green
                                            .frame(height: 1)
                                    } else {
                                        theme.border(isDark: isDark).opacity(0.25)
                                            .frame(height: 1)
                                    }
                                }
                            })
                            .onDrop(
                                of: [.text],
                                isTargeted: Binding(
                                    get: { dropTargetIndex == index },
                                    set: { hovering in
                                        if hovering {
                                            dropTargetIndex = index
                                        } else {
                                            dropTargetIndex = nil
                                        }
                                    }
                                )
                            ) { providers in
                                guard let provider = providers.first else { return false }
                                _ = provider.loadObject(ofClass: NSString.self) { value, _ in
                                    guard let draggedId = value as? String else { return }
                                    DispatchQueue.main.async {
                                        player.moveSong(id: draggedId, to: index)
                                        dropTargetIndex = nil
                                    }
                                }
                                return true
                            }
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
