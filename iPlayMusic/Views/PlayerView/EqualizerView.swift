//
//  EqualizerView.swift
//  iPlayMusic
//
//  Created by Shiv on 12/07/26.
//

import SwiftUI
import VLCKit

struct EqualizerView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var player: PlayerManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var presets: [VLCAudioEqualizer.Preset] = VLCAudioEqualizer.presets
    @State private var bands: [(Float)] = Array(repeating: 0, count: 10)
    @State private var isHovers: [Bool] = Array(repeating: false, count: 10)
    @State private var preAmplification: Float = 0
        
    var body: some View {
        ZStack {
            VStack {
                HStack(spacing: 10) {
                    Text("Base Booster")
                        .foregroundStyle(.gray)
                        .font(.system(size: 12, weight: .semibold, design: .default))
                    MacOSHorizontalSlider(progress: $preAmplification, minValue: -20, maxValue: 20, isHover: .constant(true)) { (amplification, isTracking) in
                        player.updatePreAmplification(amplification)
                    }
                    Spacer(minLength: 0)
                    Text("\(String(format: "%.0f", preAmplification * 5))%")
                        .font(.system(size: 12, weight: .light, design: .default))
                        .frame(width: 35)
                }
                .foregroundStyle(Color("#FFFFFF"))
                .padding(.horizontal, 16)
                .frame(height: 50)
                HStack(spacing: 10) {
                    VStack {
                        Text("-20 BP")
                        Spacer()
                        Text("0.0 BP")
                        Spacer()
                        Text("+20 BP")
                    }
                    .font(.system(size: 9, weight: .medium, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    HStack {
                        ForEach(bands.indices, id: \.self) { index in
                            VStack {
                                Text(String(format: "%.1f", bands[index]))
                                    .lineLimit(1)
                                VerticalSlider(progress: $bands[index], minValue: -20, maxValue: 20, isHover: $isHovers[index], onSeeking: { (amplification, isTracking) in
                                    player.updateBand(index: index, amplification: amplification)
                                })
                                .onHover { isHover in
                                    withAnimation(.bouncy) {
                                        isHovers[index] = isHover
                                    }
                                }
                                Text("Hz\(String(format: "%.0f", VLCAudioEqualizer.init().bands[index].frequency))")
                                    .lineLimit(1)
                            }
                            .font(.system(size: 9, weight: .light, design: .default))
                            .foregroundStyle(theme.text(isDark: isDark))
                        }
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                HStack {
                    Text("Equalizer")
                    Spacer()
                    Toggle(player.isOnEqualizer ? "ON  " : "OFF  ", isOn: $player.isOnEqualizer)
                        .toggleStyle(SwitchStyle(onColor: theme.theme.accent))
                }
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundStyle(theme.text(isDark: isDark))
                .frame(maxWidth: .infinity, minHeight: 35, alignment: .top)
                .onChange(of: player.isOnEqualizer) { _, isOn in
                    player.setEqualizerEnabled(isOn)
                }
                .onAppear {
                    player.eqBands.bands.enumerated().forEach { (index, band) in
                        bands[index] = band.amplification
                    }
                    // ← preAmplification bhi sync karo
                    preAmplification = player.eqBands.preAmplification
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EqualizerView()
}
