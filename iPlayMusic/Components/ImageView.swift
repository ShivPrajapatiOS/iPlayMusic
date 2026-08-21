//
//  ImagesView.swift
//  iPlayMusic
//
//  Created by Shiv on 10/07/26.
//

import SwiftUI
import SDWebImageSwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ImageView: View {
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var radius = 5.0
    
    var body: some View {
        ZStack {
            Image("img")
                .resizable()
                .scaledToFit()
//                .frame(width: 100, height: 100)
                .background {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(theme.secondaryCard(isDark: isDark))
                }
                .clipShape(RoundedRectangle(cornerRadius: radius))
                .overlay(content: {
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(theme.border(isDark: isDark), lineWidth: 1)
                })
                .shadow(color: theme.border(isDark: isDark), radius: 1, x: 0, y: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
//    ImageView()
    CircleWebImageView(url: nil)
}

struct RoundedRectangleWebImageView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @State private var didLoad = false

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }

    let url: URL?
    var thumbnail: String = "music.note"
    var radius = 5.0

    var body: some View {
        GeometryReader { size in
            WebImage(url: url, options: [.retryFailed, .continueInBackground]) { image in
                image
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: radius))
            } placeholder: {
                RoundedRectangle(cornerRadius: radius)
                    .fill(theme.secondaryCard(isDark: isDark))
                    .overlay {
                        Image(systemName: thumbnail)
                            .font(.system(size: size.size.width * 0.3, weight: .thin))
                            .scaledToFill()
                            .foregroundStyle(theme.theme.accent)
                    }
            }
            .onSuccess { _, _, cacheType in
                Task { @MainActor in
                    didLoad = true
                    print("Loaded from:", cacheType == .memory ? "Memory" : cacheType == .disk ? "Disk" : "Network")
                }
            }
            .indicator { isAnimating, _ in
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .opacity(isAnimating.wrappedValue ? 1 : 0)
            }
            .transition(didLoad ? .identity : .opacity.animation(.easeInOut(duration: 0.5)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(content: {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
            })
            .shadow(color: theme.border(isDark: isDark), radius: 1, x: 0, y: 0)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

struct RoundedRectangleDataImageView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
 
    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
 
    let data: Data?
    var thumbnail: String = "music.note"
    var radius = 5.0
 
    // Data se decode kiya hua platform image. Har render par decode na ho
    // isliye ise ek baar compute karke State me cache kar rahe hain.
#if os(macOS)
    private var decodedImage: NSImage? {
        guard let data else { return nil }
        return NSImage(data: data)
    }
#else
    private var decodedImage: UIImage? {
        guard let data else { return nil }
        return UIImage(data: data)
    }
#endif
 
    var body: some View {
        GeometryReader { size in
            Group {
                if let decodedImage {
#if os(macOS)
                    Image(nsImage: decodedImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: radius))
#else
                    Image(uiImage: decodedImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: radius))
#endif
                } else {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(theme.secondaryCard(isDark: isDark))
                        .overlay {
                            Image(systemName: thumbnail)
                                .font(.system(size: size.size.width * 0.3, weight: .thin))
                                .scaledToFill()
                                .foregroundStyle(theme.theme.accent)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(content: {
                RoundedRectangle(cornerRadius: radius)
                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
            })
            .shadow(color: theme.border(isDark: isDark), radius: 1, x: 0, y: 0)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}


struct CircleWebImageView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @State private var didLoad = false

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }

    let url: URL?
    var thumbnail: String = "music.microphone"

    var body: some View {
        GeometryReader { size in
            WebImage(url: url, options: [.retryFailed, .continueInBackground]) { image in
                image
                    .resizable()
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(theme.secondaryCard(isDark: isDark))
                    .overlay {
                        Image(systemName: thumbnail)
                            .font(.system(size: size.size.width * 0.3, weight: .thin))
                            .scaledToFill()
                            .foregroundStyle(theme.theme.accent)
                    }
            }
            .onSuccess { _, _, cacheType in
                Task { @MainActor in
                    didLoad = true
                    print("Loaded from:", cacheType == .memory ? "Memory" : cacheType == .disk ? "Disk" : "Network")
                }
            }
            .indicator { isAnimating, _ in
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.6)
                    .opacity(isAnimating.wrappedValue ? 1 : 0)
            }
            .transition(didLoad ? .identity : .opacity.animation(.easeInOut(duration: 0.5)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(content: {
                Circle()
                    .stroke(theme.border(isDark: isDark), lineWidth: 1)
            })
            .shadow(color: theme.border(isDark: isDark), radius: 1, x: 0, y: 0)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
    }
}
