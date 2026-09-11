//
//  SignInWithAppleButton.swift
//  iPlayMusic
//
//  Created by Shiv on 31/07/26.
//

import SwiftUI
import AuthenticationServices
import Combine

//struct SignInWithAppleButton: UIViewRepresentable {
//
//    var colorScheme: String
//
//    let action: () -> ()
//
//    func makeUIView(context: UIViewRepresentableContext<SignInWithAppleButton>) -> ASAuthorizationAppleIDButton {
//        ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: colorScheme == "light" ? .black : .white)
//    }
//
//    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: UIViewRepresentableContext<SignInWithAppleButton>) {
//        uiView.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped(_:)), for: .touchUpInside)
//    }
//
//    func makeCoordinator() -> SignInWithAppleButton.Coordinator {
//        Coordinator(action: self.action)
//    }
//
//    class Coordinator {
//        let action: () -> ()
//        init(action: @escaping() -> ()) {
//            self.action = action
//        }
//
//        @objc fileprivate func buttonTapped(_ sender: Any) {
//            action()
//        }
//    }
//}

import SwiftUI
import AuthenticationServices

#if os(iOS)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformAuthorizationButton = ASAuthorizationAppleIDButton
#elseif os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformAuthorizationButton = ASAuthorizationAppleIDButton
#endif

struct SignInWithAppleButton: PlatformViewRepresentable {

    var isDark: Bool
    let action: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    #if os(iOS)
    func makeUIView(context: Context) -> PlatformAuthorizationButton {
        let button = PlatformAuthorizationButton(
            authorizationButtonType: .signIn,
            authorizationButtonStyle: isDark ? .black : .white
        )
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonTapped),
            for: .touchUpInside
        )
        return button
    }

    func updateUIView(_ uiView: PlatformAuthorizationButton, context: Context) {}
    #endif

    #if os(macOS)
    func makeNSView(context: Context) -> PlatformAuthorizationButton {
        let button = PlatformAuthorizationButton(
            authorizationButtonType: .signIn,
            authorizationButtonStyle: isDark ? .black : .white
        )
        button.target = context.coordinator
        button.action = #selector(Coordinator.buttonTapped)
        return button
    }

    func updateNSView(_ nsView: PlatformAuthorizationButton, context: Context) {}
    #endif

    class Coordinator: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func buttonTapped() {
            action()
        }
    }
}

