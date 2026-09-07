//
//  LineVisualizerView.swift
//  iPlayMusic
//
//  Created by Shiv on 05/09/26.
//

import SwiftUI

struct LineVisualizerView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
 
    @State private var drawingHeight = true
 
    var animation: Animation {
        return .linear(duration: 0.5).repeatForever()
    }
 
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2.5) {
                bar(low: 0.4)
                    .animation(animation.speed(1.5), value: drawingHeight)
                bar(low: 0.3)
                    .animation(animation.speed(1.2), value: drawingHeight)
                bar(low: 0.5)
                    .animation(animation.speed(1.0), value: drawingHeight)
                bar(low: 0.3)
                    .animation(animation.speed(1.7), value: drawingHeight)
            }
            .frame(width: 25)
            .onAppear{
                drawingHeight.toggle()
            }
        }
    }
 
    func bar(low: CGFloat = 0.0, high: CGFloat = 1.0) -> some View {
        RoundedRectangle(cornerRadius: .infinity)
            .fill(theme.theme.primary)
            .frame(height: (drawingHeight ? high : low) * 25)
            .frame(height: 25, alignment: .bottom)
    }
}

#Preview {
    LineVisualizerView()
}
