//
//  ThemeManager.swift
//  iPlayMusic
//
//  Created by Shiv on 09/07/26.
//

import SwiftUI
import Combine

enum ThemeMode: String, CaseIterable {
    case system
    case light
    case dark
}


struct AppTheme {
    
    // MARK: Brand Colors
    
    let primary = Color("#CA5C5E")
    let secondary = Color("#E78B8D")
    let accent = Color("#F4A7A8")
    
    let success = Color("#48C78E")
    let warning = Color("#F6B93B")
    let error = Color("#E74C3C")
    
    // MARK: Light Theme
    
    let lightBackground = Color("#FFF8F8")
    let lightCard = Color.white
    let lightSecondaryCard = Color("#FCEEEE")
    let lightBorder = Color("#F1D7D8")
    
    // MARK: Dark Theme
    
    let darkBackground = Color("#191414")
    let darkCard = Color("#262020")
    let darkSecondaryCard = Color("#322828")
    let darkBorder = Color("#4A3B3B")
    
    // MARK: Text
    
    let lightText = Color("#2E2020")
    let lightSubText = Color("#7C6666")
    
    let darkText = Color.white
    let darkSubText = Color("#D7CACA")
    
    // MARK: Extras
    
    let divider = Color("#EADADA")
}

enum AppGradients {

    static let primary = LinearGradient(
        colors: [
            Color("#CA5C5E"),
            Color("#E78B8D")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let soft = LinearGradient(
        colors: [
            Color("#FFF5F5"),
            Color("#FCEEEE")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let music = LinearGradient(
        colors: [
            Color("#CA5C5E"),
            Color("#E78B8D"),
            Color("#FFD3D3")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

final class ThemeManager: ObservableObject {

    static let shared: ThemeManager = .init()

    let theme = AppTheme()

    @AppStorage("themeMode") var themeMode: ThemeMode = .system

    private init() {}

    func colorScheme() -> ColorScheme? {

        switch themeMode {

        case .system:
            return nil

        case .light:
            return .light

        case .dark:
            return .dark
        }
    }

    // MARK: Colors

    func background(isDark: Bool) -> Color {
        isDark ? theme.darkBackground : theme.lightBackground
    }

    func card(isDark: Bool) -> Color {
        isDark ? theme.darkCard : theme.lightCard
    }

    func secondaryCard(isDark: Bool) -> Color {
        isDark ? theme.darkSecondaryCard : theme.lightSecondaryCard
    }

    func border(isDark: Bool) -> Color {
        isDark ? theme.darkBorder : theme.lightBorder
    }

    func text(isDark: Bool) -> Color {
        isDark ? theme.darkText : theme.lightText
    }

    func subText(isDark: Bool) -> Color {
        isDark ? theme.darkSubText : theme.lightSubText
    }
}

