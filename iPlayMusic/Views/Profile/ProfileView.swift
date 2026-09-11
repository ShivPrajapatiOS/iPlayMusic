//
//  ProfileView.swift
//  iPlayMusic
//
//  Created by Shiv on 03/08/26.
//

import SwiftUI

#if os(iOS)
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmAuth: AuthenticationViewModel = .init()

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        ZStack {
            theme.background(isDark: isDark).ignoresSafeArea()
            Text("Profile")
                .font(.system(size: 20, weight: .bold, design: .default))
                .foregroundStyle(theme.text(isDark: isDark))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, content: {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(theme.theme.primary)
                        .frame(width: 35, height: 35)
                        .background(
                            Capsule()
                                .fill(theme.background(isDark: isDark)).overlay(
                                    Capsule()
                                        .stroke(theme.border(isDark: isDark), lineWidth: 0.25)
                                ))
                }
                Spacer()
                Text("Profile")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                Spacer()
                Spacer()
                    .frame(width: 35)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding(.horizontal)
            .background {
                theme.background(isDark: isDark).ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        theme.border(isDark: isDark)
                            .frame(height: 0.5)
                    }
            }
        })
        .navigationBarBackButtonHidden()
        .enableSwipeBack()
    }
}

#Preview {
    ProfileView()
}
#endif
