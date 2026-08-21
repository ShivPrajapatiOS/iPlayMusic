//
//  LoaderView.swift
//  iPlayMusic
//
//  Created by Shiv on 31/07/26.
//

import SwiftUI

struct LoaderView: View {
    
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    // MARK: - Configurable properties
    
    /// Size of the whole spinner (width == height)
    var size: CGFloat = 90
    
    /// Icon shown in the center (SF Symbol name)
    var iconName: String = "music.quarternote.3"
        
    /// How much of the circle the rotating arc covers (0...1)
    var arcFraction: CGFloat = 0.28
    
    /// One full rotation duration for the arc
    var rotationDuration: Double = 1.2
    
    /// How high the icon "jumps"
    var bounceHeight: CGFloat = 8
    
    /// Duration of one up-down bounce cycle
    var bounceDuration: Double = 0.5
            
    /// How long one full spin of the star takes (spins in place)
    var starSpinDuration: Double = 2.0
    
    // MARK: - Animation state
    
    @State private var arcAngle: Angle = .degrees(0)
    @State private var bounceOffset: CGFloat = 0
    @State private var starAngle: Angle = .degrees(0)
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.secondaryCard(isDark: isDark).opacity(0.25), lineWidth: 7)
            Circle()
                .trim(from: 0, to: arcFraction)
                .stroke(
                    theme.theme.accent,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(arcAngle)
            ZStack(alignment: .topTrailing) {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.34, height: size * 0.34)
                    .foregroundColor(theme.theme.accent)
                    .offset(y: bounceOffset)
                Image(systemName: "sparkle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.16, height: size * 0.16)
                    .foregroundColor(theme.theme.accent)
                    .rotationEffect(starAngle)
                    .offset(x: size * 0.10, y: -size * 0.08 + bounceOffset)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(
                .linear(duration: rotationDuration)
                .repeatForever(autoreverses: false)
            ) {
                arcAngle = .degrees(360)
            }
            withAnimation(
                .easeInOut(duration: bounceDuration)
                .repeatForever(autoreverses: true)
            ) {
                bounceOffset = -bounceHeight
            }
            withAnimation(
                .linear(duration: starSpinDuration)
                .repeatForever(autoreverses: false)
            ) {
                starAngle = .degrees(360)
            }
        }
    }
}

#Preview {
    LoaderView()
}


struct LoadingOverlayModifier: ViewModifier {
    @Binding var isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if isLoading {
                Color("#000000").opacity(0.6).ignoresSafeArea()
                LoaderView()
            }
        }
        .animation(.easeInOut, value: isLoading)
    }
}

extension View {
    func loadingOverlay(_ isLoading: Binding<Bool>) -> some View {
        modifier(LoadingOverlayModifier(isLoading: isLoading))
    }
}


final class GlobalLoader {

    static let shared = GlobalLoader()
    
#if !os(macOS)
    private var window: UIWindow?
#endif

    private init() {}

    func show() {
#if !os(macOS)
        guard window == nil else { return }

        // 🔹 Get active window scene
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let host = UIHostingController(
            rootView: ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                LoaderView()
            }
        )

        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        self.window = window
        #endif
    }

    func hide() {
#if !os(macOS)
        window?.isHidden = true
        window = nil
#endif
    }
}
