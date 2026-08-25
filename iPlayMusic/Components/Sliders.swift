//
//  Sliders.swift
//  iPlayMusic
//
//  Created by Shiv on 12/07/26.
//

import SwiftUI

// MARK: - MacOS Vertical Slider View
struct VerticalSlider: View {
    
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1

    let knobSize: CGFloat = 20

    var onSeeking: ((Float, Bool) -> Void)? = nil
    @Binding var isHover: Bool

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            GeometryReader { geometry in
                let trackHeight = geometry.size.height
                let knobMovementRange = trackHeight - knobSize
                
                let normalizedProgress = (CGFloat(progress) - minValue) / (maxValue - minValue)
                
                let knobY = (trackHeight - knobSize / 2) - (knobMovementRange * normalizedProgress)
                
                let filledTrackHeight = trackHeight - knobY
                
                ZStack {
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.ultraThinMaterial)
                        .frame(width: (isHover ? 7 : 2.5), height: trackHeight)
                        .position(x: geometry.size.width / 2, y: trackHeight / 2)
                        .animation(.easeInOut, value: isHover)

                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(theme.theme.accent)
                        .frame(width: (isHover ? 7 : 2.5), height: filledTrackHeight)
                        .position(
                            x: geometry.size.width / 2,
                            y: trackHeight - filledTrackHeight / 2
                        )
                        .animation(.easeInOut, value: isHover)
                    Circle()
                        .fill(theme.subText(isDark: isDark))
                        .frame(width: knobSize, height: knobSize)
                        .position(x: geometry.size.width / 2, y: knobY)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let clampedY = max(knobSize / 2, min(value.location.y, trackHeight - knobSize / 2))
                                    let newNormalized = 1 - ((clampedY - knobSize / 2) / knobMovementRange)
                                    progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                                    onSeeking?(progress, true)
                                }
                                .onEnded { _ in
                                    onSeeking?(progress, false)
                                }
                        )
                }
            }
            .frame(width: knobSize)
        }
    }
}

// MARK: - MacOS Horizontal Slider View
struct MacOSHorizontalSlider: View {
    
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var progress: Float
    
    var minValue: CGFloat = 0
    var maxValue: CGFloat = 1
    
    // नया constant: Tap/Drag करने के लिए बड़ा size
    let hitAreaSize: CGFloat = 40

    var onSeeking: ((Float, Bool) -> Void)? = nil
    @Binding var isHover: Bool

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let knobMovementRange = trackWidth - (isHover ? 7 : 2)
                 
                let normalizedProgress = (CGFloat(progress) - minValue) / (maxValue - minValue)
                 
                let knobX = ((isHover ? 7 : 2) / 2) + (knobMovementRange * normalizedProgress)
                 
                let filledTrackWidth = knobX
                 
                ZStack {
                    // 1. Track Bar (Background)
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(.gray.opacity(0.5))
                        .frame(width: trackWidth, height: isHover ? 7 : 2)
                        .animation(.easeInOut(duration: 0.5), value: isHover)
                        .position(x: trackWidth / 2, y: geometry.size.height / 2)

                    // 2. Track Bar (Filled)
                    RoundedRectangle(cornerRadius: .infinity)
                        .fill(theme.theme.accent)
                        .frame(width: filledTrackWidth, height: isHover ? 7 : 2)
                        .animation(.easeInOut(duration: 0.5), value: isHover)
                        .position(
                            x: filledTrackWidth / 2,
                            y: geometry.size.height / 2
                        )
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Drag location को clamped करें
                            let clampedX = max((isHover ? 7 : 2) / 2, min(value.location.x, trackWidth - (isHover ? 7 : 2) / 2))
                            let newNormalized = (clampedX - (isHover ? 7 : 2) / 2) / knobMovementRange
                            
                            // progress को अपडेट करें
                            progress = Float(minValue + (newNormalized * (maxValue - minValue)))
                            onSeeking?(progress, true)
                        }
                        .onEnded { _ in
                            onSeeking?(progress, false)
                        }
                )
            }
            .frame(height: hitAreaSize)
        }
        .frame(maxWidth: .infinity)
        .frame(height: isHover ? 7 : 2)
    }
}


struct TestSlider: View {
    @State private var progress: Float = 0.5
    
    @State private var isHover: Bool = false
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            VerticalSlider(progress: $progress, isHover: $isHover)
                .frame(width: 50)
                .onHover { isHover in
                    withAnimation(.bouncy) {
                        self.isHover = isHover
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TestSlider()
}
