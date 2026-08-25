//
//  QueueListPlayView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/07/26.
//

import SwiftUI

struct QueueListPlayView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var isShow: Bool
    
    var body: some View {
        ZStack {
            theme.background(isDark: isDark)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(0...50, id: \.self) { index in
                        QueueItemView()
                            .frame(height: 50)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top) {
            if isShow {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(theme.text(isDark: isDark))
                        .frame(width: 32.5, height: 32.5)
                        .background(
                            Capsule()
                                .fill(theme.background(isDark: isDark)).overlay(
                                    Capsule()
                                        .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                ))
                        .onTapGesture {
                            withAnimation(.easeInOut) {
                                isShow.toggle()
                            }
                        }
                }
                .frame(maxWidth: .infinity, minHeight: 32.5, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
            }
        }
        .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
    }
}

#Preview {
    QueueListPlayView(isShow: .constant(false))
}
