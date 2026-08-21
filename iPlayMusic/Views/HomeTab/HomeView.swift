//
//  HomeView.swift
//  iPlayMusic
//
//  Created by Shiv on 23/07/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
#if os(iOS)
    @Binding var isShowSearch: Bool
    let namespace: Namespace.ID
#endif
    
    var body: some View {
        GeometryReader { geoProxy in
#if !os(macOS)
            ZStack {
                theme.background(isDark: isDark).ignoresSafeArea()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .light, design: .default))
                            .foregroundStyle(theme.theme.primary)
                            .frame(width: 35, height: 35)
                            .background(
                                Capsule()
                                    .fill(theme.background(isDark: isDark))
                                    .overlay(
                                        Capsule()
                                            .stroke(theme.border(isDark: isDark), lineWidth: 0.25)
                                    ))
                    }
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .light, design: .default))
                        .foregroundStyle(theme.theme.primary)
                        .frame(width: 35, height: 35)
                        .background(Capsule().fill(theme.background(isDark: isDark)))
                        .matchedGeometryEffect(id: "SEARCH_ANIMATION", in: namespace)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                isShowSearch = true
                            }
                        }
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
            }
#else
            ZStack {
                Text("Home")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 16) {
                    Group {
                        Text("Home")
                            .id("Home")
                            .font(.system(size: 14, weight: .bold, design: .default))
                            .foregroundColor(theme.text(isDark: isDark))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .animation(.easeInOut(duration: 0.25), value: "Home")
                    }
                    
                    Spacer()
                    
                    HStack {
                        Menu {
                            Button {
                                print("All Albums")
                            } label: {
                                Label("All Albums", systemImage: "checkmark")
                            }
                            
                        } label: {
                            Image(systemName: "line.horizontal.3.decrease")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(theme.text(isDark: isDark))
                                .frame(width: 32.5, height: 32.5)
                                .background(
                                    Capsule()
                                        .fill(theme.background(isDark: isDark)).overlay(
                                            Capsule()
                                                .stroke(theme.border(isDark: isDark), lineWidth: 1)
                                        ))
                        }
                        .buttonStyle(.plain)
                        
                        DropDownMusicLanguageView()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 32.5)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(content: {
                    Rectangle()
                        .fill(.windowBackground)
                        .ignoresSafeArea()
                })
                .edgesIgnoringSafeArea(.init(arrayLiteral: .top))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
#endif
        }
    }
}

#if !os(macOS)
struct HomeView_Preview: View {
    @Namespace private var namespace

    var body: some View {
        HomeView(isShowSearch: .constant(false), namespace: namespace)
    }
}
#endif

#Preview {
#if !os(macOS)
    HomeView_Preview()
#else
    HomeView()
#endif
}
