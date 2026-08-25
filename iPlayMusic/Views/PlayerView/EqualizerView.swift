//
//  EqualizerView.swift
//  iPlayMusic
//
//  Created by Shiv on 12/07/26.
//

import SwiftUI

struct EqualizerView: View {
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var isHovers: [Bool] = Array(repeating: false, count: 10)
    @State private var progress: Float = 0.35
    
    @State private var isEqualizer: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
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
                        ForEach(0...9, id: \.self) { index in
                            VStack {
                                Text("0.0")
                                VerticalSlider(progress: $progress, isHover: $isHovers[index])
                                    .onHover { isHover in
                                        withAnimation(.bouncy) {
                                            isHovers[index] = isHover
                                        }
                                    }
                                    Text("24Hz")
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
                    Toggle(isEqualizer ? "ON  " : "OFF  ", isOn: $isEqualizer)
                        .toggleStyle(SwitchStyle(onColor: theme.theme.accent))
                }
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundStyle(theme.text(isDark: isDark))
                .frame(maxWidth: .infinity, minHeight: 35, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EqualizerView()
}
