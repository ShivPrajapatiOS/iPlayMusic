//
//  SplashView.swift
//  iPlayMusic
//
//  Created by Shiv on 28/07/26.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                BackgroundView()
                VStack {
                    Image("ic_splash")
                        .resizable()
                        .scaledToFit()
#if os(macOS)
                        .frame(width: geoProxy.size.width * 0.125, height: geoProxy.size.width * 0.125)
#else
                        .frame(width: geoProxy.size.width * 0.3, height: geoProxy.size.width * 0.3)
#endif
                    HStack(spacing: 0) {
                        Text("iPlay")
                            .foregroundStyle(theme.theme.accent.gradient)
                        Text(" Music")
                            .foregroundStyle(theme.text(isDark: isDark))
                    }
                    .font(.system(size: 15, weight: .semibold, design: .default))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    SplashView()
}


struct BackgroundView: View {
    @StateObject private var theme: ThemeManager = .shared
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack {
                Color.clear.ignoresSafeArea()
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.theme.accent.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .blur(radius: 40)
                    .position(x: 0, y: geoProxy.size.height * 0.15)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.theme.lightBackground.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 500
                        )
                    )
                    .frame(width: 600, height: 600)
                    .blur(radius: 50)
                    .position(x: geoProxy.size.width, y: geoProxy.size.height * 0.45)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.theme.lightCard.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 300
                        )
                    )
                    .position(x: geoProxy.size.width, y: geoProxy.size.height * 0.15)
                    .blur(radius: 75)
                    .position(x: -75, y: geoProxy.size.height * 0.85)
            }
        }
    }
}
