//
//  PlayerSettingsView.swift
//  iPlayMusic
//
//  Created by Shiv on 06/09/26.
//

import SwiftUI
import VLCKit

struct PlayerSettingsView: View {
    var body: some View {
        VStack(spacing: 15) {
            AudioChannelView()
            DecoderView()
        }
        .padding(16)
    }
}

#Preview {
    PlayerSettingsView()
}


// MARK: - DecoderView
struct DecoderView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Namespace private var animation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Decoder")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.subText(isDark: isDark))

            HStack(spacing: 1) {
                ForEach(DecoderType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 10)
                        .background {
                            if player.decoderType == type {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(theme.theme.primary)
                                    .matchedGeometryEffect(id: "DECODER_SELECT", in: animation)
                            } else {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(theme.background(isDark: isDark).opacity(0.00001))
                            }
                        }
                        .onTapGesture {
                            withAnimation(.smooth) {
                                player.decoderType = type
                            }
                        }
                }
            }
            .frame(height: 27)
            .padding(3)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .fill(theme.background(isDark: isDark))
                    .overlay {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(theme.border(isDark: isDark), lineWidth: 1)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            Text(player.decoderType == .hwDecoder ? "Hardware decoding — better battery life, lower CPU usage" : "Software decoding — more compatible, slightly higher CPU usage")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
        }
    }
}


enum AudioChannelTypes: String, CaseIterable {
    case dolbys, left, mono, rStereo, right, stereo, unset
    
    var title: String {
        switch self {
        case .dolbys: return "Dolby"
        case .left: return "Left"
        case .mono: return "Mono"
        case .rStereo: return "rStereo"
        case .right: return "Right"
        case .stereo: return "Stereo"
        case .unset: return "Unset"
        }
    }
}

struct AudioChannelView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var selectedChannel: AudioChannelTypes = .unset
    
    var body: some View {
        HStack {
            Text("Channel")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.subText(isDark: isDark))
                .frame(maxWidth: .infinity, alignment: .leading)
            Menu {
                ForEach(AudioChannelTypes.allCases, id: \.self) { type in
                    Button {
                        switch type {
                        case .dolbys:
                            player.setStereoMode(.dolbys)
                        case .left:
                            player.setStereoMode(.left)
                        case .mono:
                            player.setStereoMode(.mono)
                        case .rStereo:
                            player.setStereoMode(.rStereo)
                        case .right:
                            player.setStereoMode(.right)
                        case .stereo:
                            player.setStereoMode(.stereo)
                        case .unset:
                            player.setStereoMode(.unset)
                        }
                        selectedChannel = type
                    } label: {
                        Text(type.title)
                    }
                }
            } label: {
                Text(selectedChannel.title)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundStyle(theme.theme.primary)
            }
        }
        .frame(height: 35)
    }
}
