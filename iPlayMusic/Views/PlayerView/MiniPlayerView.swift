//
//  MiniPlayerView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI
import VLCKit

struct MiniPlayerView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared
    @StateObject private var appState: StateManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var showQueuePlaylist: Bool
    var namespace: Namespace.ID
    @State private var showSeek: Bool = false
    @State private var showEqualizer: Bool = false
    @State private var isValume: Bool = false
    
    private var isPlayerInactive: Bool {
            player.currentSong == nil && player.state == .stopped
        }
        
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                HStack {
                    Button {
                        player.isShuffle.toggle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: .light, design: .default))
                            .foregroundStyle(player.isShuffle ? theme.theme.primary : theme.text(isDark: isDark))
                            .scaledToFit()
                            .frame(height: 25)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                    Button {
                        player.previousPlay()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 30)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                    
                    Button {
                        player.playPause()
                    } label: {
                        Image(systemName: player.state == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                    
                    Button {
                        player.nextPlay()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 30)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                    
                    Button {
                        switch player.repeatMode {
                        case .doNotRepeat:
                            player.repeatMode = .repeatAllItems
                        case .repeatAllItems:
                            player.repeatMode = .repeatCurrentItem
                        case .repeatCurrentItem:
                            player.repeatMode = .doNotRepeat
                        @unknown default: break;
                        }
                    } label: {
                        Image(systemName: player.repeatMode == .repeatCurrentItem ? "repeat.1" : "repeat")
                            .font(.system(size: 11, weight: .light, design: .default))
                            .foregroundStyle(player.repeatMode == .doNotRepeat ? theme.text(isDark: isDark) : theme.theme.primary)
                            .scaledToFit()
                            .frame(height: 25)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                }
                .matchedGeometryEffect(id: "PLAYER_CONTROLS", in: namespace, isSource: !appState.showFullPlayer)
                HStack {
                    RoundedRectangleWebImageView(url: URL(string: player.currentSong?.thumbnailURL ?? ""))
                        .frame(width: 32.5, height: 32.5)
                        .matchedGeometryEffect(id: "PLAYER_ARTWORK", in: namespace, isSource: !appState.showFullPlayer)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(player.currentSong?.name ?? "Unknown")
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                            .matchedGeometryEffect(id: "PLAYER_TITLE", in: namespace, isSource: !appState.showFullPlayer)
                        Text(player.currentSong?.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                            .font(.system(size: 10, weight: .light, design: .default))
                            .foregroundStyle(theme.subText(isDark: isDark))
                            .matchedGeometryEffect(id: "PLAYER_ARTIST", in: namespace, isSource: !appState.showFullPlayer)
                    }
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .blur(radius: showSeek ? 2.5 : 0)
                .opacity(showSeek ? 0.9 : 1)
                .overlay(alignment: .bottom, content: {
                    VStack {
                        if showSeek {
                            HStack {
                                Text(player.currentDuration.stringValue)
                                Spacer()
                                Text(player.totalDuration.stringValue)
                            }
                            .font(.system(size: 11, weight: .light, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                            .padding(.horizontal, 2.5)
                        }
                        MacOSHorizontalSlider(progress: $player.position, isHover: $showSeek) { (progress, isTracking) in
                            player.seek(to: progress, isTracking: isTracking)
                        }
                    }
                    .padding(.bottom, 2.5)
                    .matchedGeometryEffect(id: "PLAYER_SEEK_SLIDER", in: namespace, isSource: !appState.showFullPlayer)
                    .onHover { isHover in
                        withAnimation(.bouncy) {
                            showSeek.toggle()
                        }
                    }
                })
                
                HStack {
                    if !isValume {
                        Button {
                            print("lyrics")
                        } label: {
                            Image(systemName: "music.pages")
                                .font(.system(size: 15, weight: .light, design: .default))
                                .scaledToFit()
                                .frame(width: 25, height: 35)
                                .background {
                                    Capsule()
                                        .fill(theme.background(isDark: isDark).opacity(0.0000001))
                                }
                        }
                        
                        Button {
                            withAnimation(.easeInOut) {
                                showQueuePlaylist.toggle()
                            }
                        } label: {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 15, weight: .light, design: .default))
                                .foregroundStyle(showQueuePlaylist ? theme.theme.accent : theme.text(isDark: isDark))
                                .scaledToFit()
                                .frame(width: 25, height: 35)
                                .background {
                                    Capsule()
                                        .fill(theme.background(isDark: isDark).opacity(0.0000001))
                                }
                        }
                        
                        Button {
                            withAnimation(.bouncy) {
                                showEqualizer.toggle()
                            }
                        } label: {
                            Image(systemName: "slider.vertical.3")
                                .font(.system(size: 15, weight: .light, design: .default))
                                .foregroundStyle(showEqualizer ? theme.theme.accent : theme.text(isDark: isDark))
                                .scaledToFit()
                                .frame(width: 25, height: 35)
                                .background {
                                    Capsule()
                                        .fill(theme.background(isDark: isDark).opacity(0.0000001))
                                }
                        }
                        .popover(isPresented: $showEqualizer) {
                            EqualizerView()
                                .padding(20)
                            .frame(width: 400, height: 250)
                        }
                    } else {
                        MacOSHorizontalSlider(progress: .constant(0.5), isHover: .constant(true))
                            .frame(width: 91)
                    }
                    
                    Button {
                        withAnimation(.bouncy) {
                            isValume.toggle()
                        }
                    } label: {
                        Image(systemName: "speaker.wave.3")
                            .font(.system(size: 15, weight: .light, design: .default))
                            .foregroundStyle(isValume ? theme.theme.accent : theme.text(isDark: isDark))
                            .scaledToFit()
                            .frame(width: 25, height: 35)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark).opacity(0.0000001))
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(height: 45)
            .frame(maxWidth: 575, alignment: .leading)
            .padding(.horizontal)
            .background(content: {
                Capsule()
                    .fill(theme.background(isDark: isDark))
                    .overlay(content: {
                        Capsule()
                            .stroke(theme.border(isDark: isDark), lineWidth: 1)
                    })
                    .shadow(color: theme.border(isDark: isDark).opacity(0.5), radius: 10, x: 0, y: 0)
                    .matchedGeometryEffect(id: "PLAYER_BACKGROUND", in: namespace, isSource: !appState.showFullPlayer)
            })
            .containerShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                    StateManager.shared.showFullPlayer = true
                }
            }
        }
        .opacity(isPlayerInactive ? 0.5 : 1.0)
        .allowsHitTesting(!isPlayerInactive)
        .padding(.bottom, 25)
    }
}

//#Preview {
//    MiniPlayerView(showQueuePlaylist: .constant(false))
//}
