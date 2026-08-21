//
//  MusicPlayerView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI

struct MusicPlayerView: View {
    @Environment(\.colorScheme) private var systemScheme

    @EnvironmentObject var appState: StateManager
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    @Binding var showQueuePlaylist: Bool
    
    @State private var progress: Float = 0.25
    
    var namespace: Namespace.ID
        
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                HStack(spacing: 0) {
                    GeometryReader { geoProxy in
                        ZStack {
                            VStack {
                                let imageSize = min(max(geoProxy.size.width * 0.4, 150), 250)
                                RoundedRectangleWebImageView(url: nil, radius: 10)
                                    .frame(width: imageSize, height: imageSize)
                                    .matchedGeometryEffect(
                                        id: "PLAYER_ARTWORK",
                                        in: namespace
                                    )
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .safeAreaInset(edge: .bottom) {
                                VStack(spacing: 40) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Falani (RiskyjaTT.CoM)")
                                                .font(.system(size: 18, weight: .semibold, design: .default))
                                                .foregroundStyle(theme.text(isDark: isDark))
                                                .matchedGeometryEffect(
                                                        id: "PLAYER_TITLE",
                                                        in: namespace
                                                    )
                                            Text("Vikram Sharkar (RiskyjaTT.CoM)")
                                                .font(.system(size: 14, weight: .regular, design: .default))
                                                .foregroundStyle(theme.subText(isDark: isDark))
                                                .matchedGeometryEffect(
                                                        id: "PLAYER_ARTIST",
                                                        in: namespace
                                                    )
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    VStack(spacing: 0) {
                                        VStack(spacing: 6) {
                                            MacOSHorizontalSlider(progress: $progress, isHover: .constant(true))
                                            HStack {
                                                Text("00:00")
                                                Spacer()
                                                Text("00:00")
                                            }
                                            .padding(.horizontal, 5)
                                            .font(.system(size: 10, weight: .light, design: .default))
                                            .foregroundStyle(theme.subText(isDark: isDark))
                                        }
                                        .matchedGeometryEffect(
                                                    id: "PLAYER_SEEK_SLIDER",
                                                    in: namespace
                                                )
                                        HStack {
                                            Button {
                                                print("")
                                            } label: {
                                                Image(systemName: "shuffle")
                                                    .font(.system(size: 16, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 25)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                            Button {
                                                print("")
                                            } label: {
                                                Image(systemName: "backward.fill")
                                                    .font(.system(size: 25, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 30)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                print("")
                                            } label: {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 35, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(width: 35, height: 35)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                print("")
                                            } label: {
                                                Image(systemName: "forward.fill")
                                                    .font(.system(size: 25, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 30)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                            
                                            Button {
                                                print("")
                                            } label: {
                                                Image(systemName: "repeat")
                                                    .font(.system(size: 16, weight: .light, design: .default))
                                                    .scaledToFit()
                                                    .frame(height: 25)
                                                    .background {
                                                        Capsule()
                                                            .fill(theme.background(isDark: isDark))
                                                    }
                                            }
                                            .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.plain)
                                        .frame(maxWidth: .infinity)
                                        .matchedGeometryEffect(
                                                    id: "PLAYER_CONTROLS",
                                                    in: namespace
                                                )
                                    }
                                }
                            }
                            .frame(width: geoProxy.size.width * 0.75, height: geoProxy.size.height * 0.8, alignment: .top)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    VStack {
                        HStack {
                            Button {
                                print("auto play")
                            } label: {
                                HStack {
                                    Image(systemName: "infinity")
                                    Text("AutoPlay")
                                }
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(theme.theme.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background {
                                    Capsule()
                                        .fill(theme.text(isDark: isDark).opacity(0.25))
                                }
                            }
                            Button {
                                print("auto play")
                            } label: {
                                HStack {
                                    Image(systemName: "infinity")
                                    Text("AutoPlay")
                                }
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(theme.theme.accent)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background {
                                    Capsule()
                                        .fill(theme.text(isDark: isDark).opacity(0.25))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(height: 32.5)
                        .padding(.horizontal, 50)
                        
                        ScrollView(.vertical) {
                            LazyVStack(spacing: 0) {
                                ForEach(0...10, id: \.self) { index in
                                    QueueItemView()
                                        .frame(height: 50)
                                        .overlay(alignment: .bottom) {
                                            if index != 9 {
                                               Capsule()
                                                    .fill(theme.secondaryCard(isDark: isDark).opacity(0.25))
                                                    .frame(height: 1)
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(width: geoProxy.size.width * 0.5)
                }
                .frame(width: geoProxy.size.width - 30, height: geoProxy.size.height - 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 16) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(theme.text(isDark: isDark))
                                .frame(width: 32.5, height: 32.5)
                                .background(
                                    Capsule()
                                        .fill(theme.background(isDark: isDark)).overlay(
                                            Capsule()
                                                .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                        ))
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
                                        appState.showFullPlayer = false
                                    }
                                }
                    
                    Spacer()
                    
                    HStack {
                        MacOSHorizontalSlider(progress: $progress, isHover: .constant(true))
                            Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(theme.text(isDark: isDark))
                    }
                    .padding(.horizontal, 10)
                    .frame(width: 200, height: 32.5)
                    .background(
                        Capsule()
                            .fill(theme.background(isDark: isDark)).overlay(
                                Capsule()
                                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
                            ))
                }
                .frame(maxWidth: .infinity, minHeight: 32.5)
                .padding(.vertical, 10)
                .padding(.leading, 100)
                .padding(.trailing, 10)
            }
            .background {
                theme.background(isDark: isDark).ignoresSafeArea()
                    .matchedGeometryEffect(
                                id: "PLAYER_BACKGROUND",
                                in: namespace
                            )
            }
            .ignoresSafeArea()
        }
    }
}

struct MusicPlayerView_Preview: View {
    @Namespace var animation
    var body: some View {
        MusicPlayerView(showQueuePlaylist: .constant(false), namespace: animation)
    }
}

#Preview {
    MusicPlayerView_Preview()
}
