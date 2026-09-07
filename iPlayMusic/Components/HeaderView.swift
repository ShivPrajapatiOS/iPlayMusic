//
//  HeaderView.swift
//  iPlayMusic
//
//  Created by Shiv on 15/07/26.
//

import SwiftUI

enum MyPlaylistMenuType {
    case edit, play, shuffle, addToQueue, delete
}

#if os(macOS)
struct HeaderView: View {
    @Environment(\.colorScheme) private var systemScheme
    
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    @Binding var selectedTab: SideTabBar
    let title: String
    @Binding var txtSearch: String
    @Binding var showCreatePlaylist: Bool
    
    @State private var isShowSheetDownloaded: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Group {
                Text(title)
                    .id(title)
                    .font(.system(size: 14, weight: .bold, design: .default))
                    .foregroundColor(theme.text(isDark: isDark))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.25), value: title)
            }
            
            Spacer()
            
            HStack {
                HStack {
                    Menu {
                        Divider()
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
                }
                .buttonStyle(.plain)
                
                if selectedTab == .myPlaylists {
                    Button {
                        showCreatePlaylist.toggle()
                    } label: {
                        Image(systemName: "plus")
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
                }
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .medium))
                    
                    TextField("Find in \(title)", text: $txtSearch)
                        .font(.system(size: 11, weight: .regular, design: .default))
                        .foregroundColor(theme.text(isDark: isDark))
                        .textFieldStyle(.plain)
                    
                    if !txtSearch.isEmpty {
                        Button(action: { txtSearch.removeAll() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .frame(width: 240, height: 32.5)
                .background(
                    Capsule()
                        .fill(theme.background(isDark: isDark))
                        .overlay(
                            Capsule()
                                .stroke(theme.border(isDark: isDark), lineWidth: 1)
                        )
                )
                
                Button {
                    withAnimation {
                        isShowSheetDownloaded = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.down.badge.checkmark")
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
        .sheet(isPresented: $isShowSheetDownloaded) {
            DownloadedSongsView()
                .frame(width: 475, height: 475)
        }
    }
}

struct BackButtonHeaderView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    let backType: SideTabBar

    var myPlaylistMenuAction: ((MyPlaylistMenuType) -> Void)? = nil
    let backAction: (() -> Void)
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "chevron.backward")
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
                    backAction()
                }
            
            Spacer()
            
            HStack {
                if backType == .myPlaylists {
                    Menu {
                        Button {
                            myPlaylistMenuAction?(.edit)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Divider()
                        Button {
                            myPlaylistMenuAction?(.play)
                        } label: {
                            Label("Play", systemImage: "play")
                        }
                        Button {
                            myPlaylistMenuAction?(.shuffle)
                        } label: {
                            Label("Shuffle", systemImage: "shuffle")
                        }
                        Button {
                            myPlaylistMenuAction?(.addToQueue)
                        } label: {
                            Label("Add to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
                        }
                        Divider()
                        Button {
                            myPlaylistMenuAction?(.delete)
                        } label: {
                            Label("Delete Playlist", systemImage: "trash")
                                .tint(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
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
                }
                
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
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 32.5)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background(content: {
            Rectangle()
                .fill(.windowBackground)
                .ignoresSafeArea()
        })
    }
}

struct HeaderDetailsView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared

    var artistName: String
    var imageURL: String
    var scrollProgress: CGFloat // Progress: 0.0 -> 1.0
    var backAction: (() -> Void)? = nil

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back Button
            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(theme.text(isDark: isDark))
                .frame(width: 32.5, height: 32.5)
                .background(
                    Capsule()
                        .fill(theme.background(isDark: isDark))
                        .overlay(Capsule().stroke(theme.border(isDark: isDark), lineWidth: 1))
                )
                .onTapGesture { backAction?() }
            
            Spacer()
            
            // CENTER: Animated Image & Title
            HStack(spacing: 8) {
                RoundedRectangleWebImageView(
                    url: URL(string: imageURL),
                    thumbnail: "music.microphone",
                    radius: 6
                )
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(artistName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .lineLimit(1)
            }
            .opacity(scrollProgress) // Scroll hone par fade in hoga
            .scaleEffect(0.7 + (0.3 * scrollProgress)) // Small to Normal scale transition
            .offset(y: (1 - scrollProgress) * 10) // Smooth drop-in effect
            
            Spacer()
            
            // Right Menu Button
            Menu {
                Button("All Albums") { print("All Albums") }
            } label: {
                Image(systemName: "line.horizontal.3.decrease")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(theme.text(isDark: isDark))
                    .frame(width: 32.5, height: 32.5)
                    .background(
                        Capsule()
                            .fill(theme.background(isDark: isDark))
                            .overlay(Capsule().stroke(theme.border(isDark: isDark), lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 45) // Safe area inset handling
        .padding(.bottom, 10)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial) // Glassmorphism backdrop effect
                .opacity(Double(scrollProgress))
                .ignoresSafeArea()
        )
    }
}


#Preview {
    HeaderView(selectedTab: .constant(.myPlaylists), title: "Artist", txtSearch: .constant(""), showCreatePlaylist: .constant(false))
}
#endif


//  DetailScreenLifecycleModifier.swift

#if os(macOS)
struct DetailScreenLifecycleModifier: ViewModifier {
    @StateObject private var appState: StateManager = .shared
    @State private var hasEnteredDetail = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasEnteredDetail {
                    hasEnteredDetail = true
                    appState.pushDetailScreen()
                }
            }
            .onDisappear {
                if hasEnteredDetail {
                    hasEnteredDetail = false
                    appState.popDetailScreen()
                }
            }
    }
}

extension View {
    func trackDetailScreenLifecycle() -> some View {
        modifier(DetailScreenLifecycleModifier())
    }
}
#endif
