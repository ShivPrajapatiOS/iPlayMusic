//
//  QueueItemView.swift
//  iPlayMusic
//
//  Created by Shiv on 17/07/26.
//

import SwiftUI

struct QueueItemView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangleWebImageView(url: nil, radius: 5)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("Flani (RiskyjaTT.Com)")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                Text("Vikram Sarkar (RiskyjaTT.Com) - Flani (RiskyjaTT.Com)")
                    .font(.system(size: 11, weight: .light, design: .default))
                    .foregroundStyle(theme.subText(isDark: isDark))
            }
        }
//        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
    }
}

#Preview {
    QueueItemView()
}
