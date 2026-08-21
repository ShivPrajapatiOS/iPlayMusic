//
//  iPlayMusicApp.swift
//  iPlayMusic
//
//  Created by Shiv on 09/07/26.
//

import SwiftUI

#if os(macOS)
@main
struct iPlayMusicApp: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    
    private let access = SharedRealm.getSharedRealmConfiguration()
    
    @StateObject private var appState: StateManager = .shared
    @StateObject private var theme = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isSplash {
                    SplashView()
                } else {
                    if appState.isLoggedIn {
                        ContentView()
                    } else {
                        SocialSignView()
                            .environmentObject(AuthenticationViewModel())
                    }
                }
            }
            .preferredColorScheme(theme.colorScheme())
            .frame(minWidth: 975, minHeight: 575)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
#else
@main
struct iPlayMusicApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let access = SharedRealm.getSharedRealmConfiguration()
    
    @StateObject private var appState: StateManager = .shared
    @StateObject private var theme = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isSplash {
                    SplashView()
                } else {
                    if appState.isLoggedIn {
                        ContentView()
                    } else {
                        SocialSignView()
                            .environmentObject(AuthenticationViewModel())
                    }
                }
            }
        }
    }
}
#endif
