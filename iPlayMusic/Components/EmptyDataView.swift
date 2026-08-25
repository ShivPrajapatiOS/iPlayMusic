//
//  EmptyDataView.swift
//  iPlayMusic
//
//  Created by Shiv on 25/08/26.
//

import SwiftUI

struct EmptyDataView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let icon: String
    let title: String
    let subTitle: String
    
    var body: some View {
        ZStack {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 55, weight: .light))
                    .foregroundStyle(theme.subText(isDark: isDark))
                    .frame(width: 100, height: 100)
                    .background {
                        Circle()
                            .fill(theme.secondaryCard(isDark: isDark))
                    }
                
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(theme.text(isDark: isDark))
                    
                    Text(subTitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(theme.subText(isDark: isDark))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyDataView(icon: "music.note.list", title: "No Songs Found", subTitle: "Search for a song to start listening.")
}
