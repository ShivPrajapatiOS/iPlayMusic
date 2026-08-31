//
//  AppDelegate.swift
//  iPlayMusic
//
//  Created by Shiv on 10/07/26.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif
import SwiftUI
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

#if os(macOS)
class MacAppDelegate: NSObject, NSApplicationDelegate {
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        FirebaseApp.configure()
        remoteConfigCall()
#if targetEnvironment(macCatalyst)
print("Mac Catalyst")
#elseif os(macOS)
print("Native macOS")
#else
print("iOS")
#endif
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if GIDSignIn.sharedInstance.handle(url) {
                return
            }
        }
    }
}
#elseif os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        remoteConfigCall()
//        PTPurchaseClass.retrievAllProducts()
//        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
//            for purchase in purchases {
//                switch purchase.transaction.transactionState {
//                case .purchased, .restored:
//                    SwiftyStoreKit.finishTransaction(purchase.transaction)
//                default:
//                    break
//                }
//            }
//        }
//        PTPurchaseClass().verifySubscriptions {
//            print(AppStateManager.shared.isPurchased)
//        }
//        AppStateManager.shared.appOpenCount += 1
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        return false
    }
}


extension UIApplication {
    static func topViewController(base: UIViewController? = nil) -> UIViewController? {
        
        let base = base ?? UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }?.rootViewController
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        
        return base
    }
}
#endif

public func remoteConfigCall() {
    RemoteConfigResponse.getResponse {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
            withAnimation(.easeInOut) {
                StateManager.shared.isSplash = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                StateManager.shared.isShowPurchase = ((!StateManager.shared.isPurchased) && (!StateManager.shared.isShowPurchase))
            })
        })
    }
}
