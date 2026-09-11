//
//  SocialSignView.swift
//  iPlayMusic
//
//  Created by Shiv on 30/07/26.
//

import SwiftUI

struct SocialSignView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @EnvironmentObject var vmAuth: AuthenticationViewModel
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
#if !os(macOS)
        ZStack {
            VStack {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        SignInWithAppleButton(isDark: isDark) {}
                            .overlay {
                                HStack {
                                    Image(systemName: "apple.logo")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(Color("#FFFFFF"))
                                        .frame(width: 20, height: 20)
                                    Text("Apple Sign In")
                                        .font(.system(size: 16, weight: .semibold, design: .default))
                                        .foregroundStyle(Color("#FFFFFF"))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color("#000000"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                            .onTapGesture {
                                Task {
                                    vmAuth.isLoading = true
                                    await vmAuth.login(with: .signInWithApple)
                                }
                            }
                            .onChange(of: vmAuth.appleSingInChanged) {
                                if vmAuth.state == .signedIn && vmAuth.signInMethod == .apple {
                                    vmAuth.isLoading = false
                                } else if vmAuth.signInMethod == .unknown {
                                    vmAuth.isLoading = false
                                }
                            }
                        
                        HStack {
                            Image("ic_google")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                            Text("Google Sign In")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundStyle(Color("#000000"))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(Color("#FFFFFF"))
                        }
                        .onTapGesture {
                            Task {
                                vmAuth.isLoading = true
                                await vmAuth.login(with: .signInWithGoogle)
                                dismiss()
                                GlobalLoader.shared.hide()
                                vmAuth.isLoading = false
                            }
                        }
                    }
                    if !appState.isAnonymous {
                        HStack {
                            Capsule()
                                .fill(theme.subText(isDark: isDark).opacity(0.25))
                                .frame(width: 50, height: 1)
                            Text("OR")
                                .font(.system(size: 11, weight: .semibold, design: .default))
                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                            Capsule()
                                .fill(theme.subText(isDark: isDark).opacity(0.25))
                                .frame(width: 50, height: 1)
                        }
                        .frame(height: 30, alignment: .bottom)
                        Button {
                            Task {
                                do {
                                    GlobalLoader.shared.show()
                                    vmAuth.isLoading = true
                                    try await vmAuth.signInWithAnonymously()
                                    vmAuth.isLoading = false
                                    GlobalLoader.shared.hide()
                                } catch {
                                    vmAuth.isLoading = false
                                    GlobalLoader.shared.hide()
                                    vmAuth.errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("Skip to Now")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundStyle(Color(theme.theme.primary))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color("#FFFFFF").opacity(0.00001))
                                }
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 25)
                .padding(.vertical, 25)
                
                VStack(spacing: 20) {
                    Text("To get started with the iPlay Music app, \n sign in with Apple or Google, or simply press the Skip to now \nto begin continuous streaming.")
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 0) {
                        Text("By clicking button ahove, you agree to our")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                        Button {
                            print("Terms")
                        } label: {
                            Text(" Terms")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundStyle(theme.theme.accent)
                        }
                        
                        Text(" and")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                            .frame(maxHeight: .infinity)
                        
                        Button {
                            print("Privacy")
                        } label: {
                            Text(" Privacy")
                                .font(.system(size: 12, weight: .semibold, design: .default))
                                .foregroundStyle(theme.theme.accent)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(height: 20)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .background {
            GeometryReader { geoProxy in
                ZStack(alignment: .bottom) {
                    theme.background(isDark: isDark)
                    Image("ic_model")
                        .resizable()
                        .frame(height: geoProxy.size.height * 0.75)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .blendMode(.saturation)
                        .blur(radius: 2.5, opaque: false)
                    theme.background(isDark: isDark)
                        .frame(height: geoProxy.size.height * 0.45)
                        .shadow(color: theme.background(isDark: isDark), radius: 100, x: 0, y: -100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea()
            }
        }
#else
        ZStack {
            theme.background(isDark: isDark).ignoresSafeArea()
            GeometryReader { geoProxy in
                HStack {
                    Image("ic_model")
                        .resizable()
                        .scaledToFit()
                        .frame(width: ((geoProxy.size.width * 0.5) - 30))
                    //                        .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(spacing: 10) {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .bold, design: .serif))
                            .foregroundStyle(theme.text(isDark: isDark))
                        
                        Spacer(minLength: 10)
                        Image("ic_splash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        Spacer(minLength: 10)
                        VStack(spacing: 0) {
                            VStack(spacing: 20) {
                                SignInWithAppleButton(isDark: isDark) {}
                                    .frame(height: 35)
                                    .overlay {
                                        HStack {
                                            Image(systemName: "apple.logo")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(Color("#FFFFFF"))
                                                .frame(width: 15, height: 15)
                                            Text("Apple Sign In")
                                                .font(.system(size: 12, weight: .regular, design: .default))
                                                .foregroundStyle(Color("#FFFFFF"))
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color("#000000"))
                                        }
                                    }
                                    .frame(width: geoProxy.size.width * 0.25)
                                    .onTapGesture {
                                        Task {
                                            vmAuth.isLoading = true
                                            await vmAuth.login(with: .signInWithApple)
                                        }
                                    }
                                    .onChange(of: vmAuth.appleSingInChanged) {
                                        if vmAuth.state == .signedIn && vmAuth.signInMethod == .apple {
                                            vmAuth.isLoading = false
                                        } else if vmAuth.signInMethod == .unknown {
                                            vmAuth.isLoading = false
                                        }
                                    }
                                
                                HStack {
                                    Image("ic_google")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 15, height: 15)
                                    Text("Google Sign In")
                                        .font(.system(size: 12, weight: .regular, design: .default))
                                        .foregroundStyle(Color("#000000"))
                                }
                                .frame(width: geoProxy.size.width * 0.25)
                                .frame(height: 35)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color("#FFFFFF"))
                                }
                                .onTapGesture {
                                    Task {
                                        vmAuth.isLoading = true
                                        await vmAuth.login(with: .signInWithGoogle)
                                        dismiss()
                                        GlobalLoader.shared.hide()
                                        vmAuth.isLoading = false
                                    }
                                }
                            }
                            if !appState.isAnonymous {
                                HStack {
                                    Capsule()
                                        .fill(theme.subText(isDark: isDark).opacity(0.25))
                                        .frame(width: 50, height: 1)
                                    Text("OR")
                                        .font(.system(size: 11, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.subText(isDark: isDark).opacity(0.25))
                                    Capsule()
                                        .fill(theme.subText(isDark: isDark).opacity(0.25))
                                        .frame(width: 50, height: 1)
                                }
                                .frame(height: 30, alignment: .bottom)
                                Button {
                                    Task {
                                        do {
                                            GlobalLoader.shared.show()
                                            vmAuth.isLoading = true
                                            try await vmAuth.signInWithAnonymously()
                                            vmAuth.isLoading = false
                                            GlobalLoader.shared.hide()
                                        } catch {
                                            vmAuth.isLoading = false
                                            GlobalLoader.shared.hide()
                                            vmAuth.errorMessage = error.localizedDescription
                                        }
                                    }
                                } label: {
                                    Text("Skip to Now")
                                        .font(.system(size: 12, weight: .regular, design: .default))
                                        .foregroundStyle(Color(theme.theme.primary))
                                        .frame(width: geoProxy.size.width * 0.25)
                                        .frame(minHeight: 30)
                                        .background {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color("#FFFFFF").opacity(0.00001))
                                        }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer(minLength: 10)
                        VStack {
                            Text("To get started with the iPlay Music app, sign in with Apple or Google, \n or simply press the Skip to now to begin continuous streaming.")
                                .font(.system(size: 9, weight: .regular, design: .default))
                                .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                .multilineTextAlignment(.center)
                            HStack(spacing: 0) {
                                Text("By clicking button ahove, you agree to our")
                                    .font(.system(size: 9, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                Button {
                                    print("Terms")
                                } label: {
                                    Text(" Terms")
                                        .font(.system(size: 9, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.theme.accent)
                                }
                                
                                Text(" and")
                                    .font(.system(size: 9, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark).opacity(0.5))
                                    .frame(maxHeight: .infinity)
                                
                                Button {
                                    print("Privacy")
                                } label: {
                                    Text(" Privacy")
                                        .font(.system(size: 9, weight: .semibold, design: .default))
                                        .foregroundStyle(theme.theme.accent)
                                        .frame(maxHeight: .infinity)
                                }
                                
                            }
                            .frame(height: 20)
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 50)
                    .padding(.trailing, 30)
                }
                .ignoresSafeArea()
            }
            .frame(maxWidth: 975, maxHeight: 575)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .loadingOverlay($vmAuth.isLoading)
#endif
    }
}

#Preview {
    SocialSignView()
        .environmentObject(AuthenticationViewModel())
}
