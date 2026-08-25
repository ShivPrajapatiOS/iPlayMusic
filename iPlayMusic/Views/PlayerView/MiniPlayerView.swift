//
//  MiniPlayerView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI

struct MiniPlayerView: View {
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

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
    
    @State private var seekProgress: Float = 0.25
    
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                HStack {
                    Button {
                        print("")
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 11, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 25)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                    Button {
                        print("")
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 13, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 30)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                    
                    Button {
                        print("")
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 20, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(width: 35, height: 35)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                    
                    Button {
                        print("")
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 13, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 30)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                    
                    Button {
                        print("")
                    } label: {
                        Image(systemName: "repeat")
                            .font(.system(size: 11, weight: .light, design: .default))
                            .scaledToFit()
                            .frame(height: 25)
                            .background {
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                }
                .matchedGeometryEffect(
                            id: "PLAYER_CONTROLS",
                            in: namespace
                        )
                HStack {
                    RoundedRectangleWebImageView(url: nil)
                        .frame(width: 32.5, height: 32.5)
                        .matchedGeometryEffect(
                                id: "PLAYER_ARTWORK",
                                in: namespace
                            )
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Naresh Narayan - Aaja Ve Mahiya (Unforgettable) Lo-Fi Flip ft. Imran Khan")
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                            .matchedGeometryEffect(
                                    id: "PLAYER_TITLE",
                                    in: namespace
                                )
                        Text("Mubeen Butt")
                            .font(.system(size: 10, weight: .light, design: .default))
                            .foregroundStyle(theme.subText(isDark: isDark))
                            .matchedGeometryEffect(
                                    id: "PLAYER_ARTIST",
                                    in: namespace
                                )
                    }
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: showSeek ? 2.5 : 0)
                .opacity(showSeek ? 0.9 : 1)
                .overlay(alignment: .bottom, content: {
                    VStack {
                        if showSeek {
                            HStack {
                                Text("02:00")
                                Spacer()
                                Text("05:00")
                            }
                            .font(.system(size: 11, weight: .light, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                            .padding(.horizontal, 2.5)
                        }
                        MacOSHorizontalSlider(progress: $seekProgress, isHover: $showSeek)
                    }
                    .padding(.bottom, 2.5)
                    .matchedGeometryEffect(
                                id: "PLAYER_SEEK_SLIDER",
                                in: namespace
                            )
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
                                        .fill(theme.background(isDark: isDark))
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
                                        .fill(theme.background(isDark: isDark))
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
                                        .fill(theme.background(isDark: isDark))
                                }
                        }
                        .popover(isPresented: $showEqualizer) {
                            EqualizerView()
                                .padding(20)
                            .frame(width: 400, height: 250)
                        }
                    } else {
                        MacOSHorizontalSlider(progress: $seekProgress, isHover: .constant(true))
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
                                    .fill(theme.background(isDark: isDark))
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(height: 45)
            .frame(maxWidth: 575, alignment: .leading)
            .padding(.horizontal)
            .background {
                Capsule()
                    .fill(theme.background(isDark: isDark))
                    .overlay(content: {
                        Capsule()
                            .stroke(theme.border(isDark: isDark), lineWidth: 1)
                    })
                    .shadow(color: theme.border(isDark: isDark).opacity(0.5), radius: 10, x: 0, y: 0)
                    .matchedGeometryEffect(
                                id: "PLAYER_BACKGROUND",
                                in: namespace
                            )
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.55,
                                      dampingFraction: 0.88)) {
                    StateManager.shared.showFullPlayer = true
                }
            }
        }
        .padding(.bottom, 25)
    }
}

//#Preview {
//    MiniPlayerView(showQueuePlaylist: .constant(false))
//}
