//
//  SettingsView.swift
//  iPlayMusic
//
//  Created by Shiv on 01/08/26.
//

#if os(macOS)
import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI
import FirebaseCore
import Firebase

enum SettingTabType: String, CaseIterable {
    case general, account, playback, support
    
    var title: String {
        switch self {
        case .playback: return "Playback"
        case .general: return "General"
        case .account: return "Account"
        case .support: return "Support"
        }
    }
    
    var icon: String {
        switch self {
        case .playback: return "play.square"
        case .general: return "gearshape"
        case .account: return "person.circle"
        case .support: return "text.document"
        }
    }
}

enum SupportType: String, CaseIterable {
    case fAQ, rateApp, share, feedback, terms, privacy
    
    var title: String {
        switch self {
        case .fAQ: return "FAQ"
        case .rateApp: return "Rate App"
        case .share: return "Share"
        case .feedback: return "Feedback"
        case .terms: return "Terms of Service"
        case .privacy: return "Privacy Policy"
        }
    }
    
    var icon: String {
        switch self {
        case .fAQ: return "questionmark.circle"
        case .rateApp: return "star"
        case .share: return "square.and.arrow.up"
        case .feedback: return "bubble.right"
        case .terms: return "text.document"
        case .privacy: return "checkmark.shield"
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var vmAuth: AuthenticationViewModel = .init()

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var selectedTab: SettingTabType = .account
    
    @Namespace private var animation
    
    @State private var shareView: NSView?
    @State private var isHoverClose: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Text("Settings")
                    .font(.system(size: 13, weight: .bold, design: .default))
                    .foregroundColor(theme.text(isDark: isDark))
                    .frame(height: 30)
                
                HStack {
                    ForEach(SettingTabType.allCases, id: \.self) { tab in
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium, design: .default))
                        }
                        .foregroundStyle(selectedTab == tab ? theme.theme.primary : theme.subText(isDark: isDark))
                        .frame(maxHeight: .infinity)
                        .padding(.horizontal, 10)
                        .background {
                            ZStack {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(theme.secondaryCard(isDark: isDark))
                                        .matchedGeometryEffect(id: "SELECTED_SETTING_TAB", in: animation)
                                } else {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(theme.background(isDark: isDark))
                                }
                            }
                        }
                        .onTapGesture {
                            withAnimation(.smooth) {
                                selectedTab = tab
                            }
                        }
                    }
                }
                .frame(height: 38)
                ZStack {
                    switch selectedTab {
                    case .general:
                        Text("General")
                    case .account:
                        AccountTabView(vmAuth: vmAuth)
                    case .playback:
                        Text("Playback")
                    case .support:
                        SupportTabView(shareView: $shareView) { supportTabsAction($0) }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.vertical, 15)
            .background {
                RoundedRectangle(cornerRadius: 0)
                    .fill(theme.background(isDark: isDark))
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Circle()
                            .fill(Color("#FF5F56"))
                            .frame(width: 14, height: 14)
                            .overlay {
                                if isHoverClose {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .black, design: .default))
                                        .foregroundStyle(Color("#000000"))
                                }
                            }
                    })
                    .buttonStyle(.plain)
                    .onHover(perform: { isHoverClose = $0 })
                    Button(action: {
                        print("Full Screen")
                    }, label: {
                        Circle()
                            .fill(.gray)
                            .frame(width: 14, height: 14)
                    })
                    .disabled(true)
                    .buttonStyle(.plain)
                    Button(action: {
                        print("Full Screen")
                    }, label: {
                        Circle()
                            .fill(.gray)
                            .frame(width: 14, height: 14)
                    })
                    .disabled(true)
                    .buttonStyle(.plain)
                }
                .padding(.leading, 15)
                .padding(.top, 15)
            }
        }
        .frame(width: 390, height: 350, alignment: .top)
        .ignoresSafeArea()
    }
    
    private func supportTabsAction(_ type: SupportType) {
        switch type {
        case .fAQ:
            if let url = Bundle.main.url(forResource: "ToDoFaq", withExtension: "html") {
                WindowManager.shared.openWindow(id: .web, title: "", view: AnyView(MacWebView(htmlFileName: "ToDoFaq")))
            } else {
                print("FAQ file not found")
            }
        case .rateApp:
            if let url = URL(string: "https://apps.apple.com/app/id\(6758654695)?action=write-review") {
                NSWorkspace.shared.open(url)
            }
        case .share:
            let appURL = URL(string: "https://apps.apple.com/app/id6758654695")!
            let title = "A simple and powerful To-Do List app to manage tasks efficiently."
            let subtitle = "Stay focused. Stay productive."
            let text = """
                        \(title)
                        \(subtitle)
                
                        Download here 👇
                        \(appURL.absoluteString)
                """
            let picker = NSSharingServicePicker(items: [text, appURL])
            if let view = shareView {
                picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
            }
        case .feedback:
            print("FAQ file not found")
        case .terms:
            print("FAQ file not found")
        case .privacy:
            print("FAQ file not found")
        }
    }
}

struct AccountTabView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @ObservedObject var vmAuth: AuthenticationViewModel

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var currentUser: FirebaseAuth.User?
    
    @State private var showLogoutAlert: Bool = false
    
    var body: some View {
        ZStack {
            VStack {
                Group {
                    if appState.isLoggedIn && (currentUser?.isAnonymous == false) {
                        VStack {
                            WebImage(url: currentUser?.providerData.first(where: { $0.photoURL != nil })?.photoURL) { image in
                                image
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
                            } placeholder: {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 30, weight: .regular, design: .default))
                                    .foregroundStyle(Color("#6E6E73"))
                            }
                            .indicator(.activity)
                            .transition(.fade(duration: 0.5))
                            .frame(width: 40, height: 40, alignment: .top)
                            .scaledToFit()
                            VStack {
                                Text(currentUser?.providerData.first(where: { $0.displayName != nil })?.displayName ?? "Hello")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                Text(currentUser?.providerData.first(where: { $0.email != nil })?.email ?? "")
                                    .font(.system(size: 10, weight: .regular, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                            }
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "crown")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(theme.theme.primary)
                                    Text("Premium")
                                        .font(.system(size: 10, weight: .medium, design: .default))
                                        .foregroundStyle(theme.text(isDark: isDark))
                                    Spacer(minLength: 10)
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 8, weight: .bold, design: .default))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 35)
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.secondaryCard(isDark: isDark))
                                })
                                .overlay(alignment: .bottom) {
                                    theme.subText(isDark: isDark).opacity(0.1)
                                        .frame(height: 1)
                                }
                                HStack {
                                    Image(systemName: "power")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 12, height: 12)
                                        .foregroundStyle(Color("#F59E0B"))
                                    Text("Sign Out")
                                        .font(.system(size: 10, weight: .medium, design: .default))
                                        .foregroundStyle(theme.text(isDark: isDark))
                                    Spacer(minLength: 10)
                                    Image(systemName: "chevron.forward")
                                        .font(.system(size: 8, weight: .bold, design: .default))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 35)
                                .background(content: {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(theme.secondaryCard(isDark: isDark))
                                })
                                .onTapGesture {
                                    showLogoutAlert.toggle()
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(content: {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(theme.secondaryCard(isDark: isDark))
                            })
                            .padding(.horizontal, 15)
                        }
                        Spacer()
                    } else {
                        VStack {
                            VStack {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(theme.subText(isDark: isDark))
                                        .frame(width: 20, height: 20)
                                    Text("Anonymous")
                                        .font(.system(size: 14, weight: .medium, design: .default))
                                        .foregroundStyle(theme.text(isDark: isDark))
                                }
                                Text("Sign in to sync your tasks across devices and keep your data safe.")
                                    .font(.system(size: 9, weight: .light, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            VStack(spacing: 10) {
                                SignInWithAppleButton(isDark: isDark) {}
                                    .overlay(content: {
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
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: 35)
                                        .background {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color("#000000"))
                                        }
                                    })
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
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 35)
                                    .background {
                                        RoundedRectangle(cornerRadius: 7)
                                            .fill(Color("#FFFFFF"))
                                    }
                                    .onTapGesture {
                                        Task {
                                            vmAuth.isLoading = true
                                            await vmAuth.login(with: .signInWithGoogle)
                                            GlobalLoader.shared.hide()
                                            vmAuth.isLoading = false
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 35)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(content: {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.secondaryCard(isDark: isDark))
        })
        .padding(.horizontal, 15)
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                vmAuth.signOut()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .onAppear {
            Task {
                currentUser = await vmAuth.getCurrentUser()
            }
        }
        .onChange(of: appState.uid) {
            if !appState.uid.isEmpty {
                Task {
                    currentUser = await vmAuth.getCurrentUser()
                }
            }
        }
    }
}

// MARK: - Support Tab View
struct SupportTabView: View {
    @Environment(\.colorScheme) private var systemScheme

    @StateObject private var theme: ThemeManager = .shared

    var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var shareView: NSView?
    
    let action: ((SupportType) -> Void)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SupportType.allCases, id: \.self) { tab in
                HStack {
                    Image(systemName: tab.icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(theme.theme.primary)
                    Text(tab.title)
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                    Spacer(minLength: 10)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 8, weight: .bold, design: .default))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 35)
                .background(content: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.secondaryCard(isDark: isDark))
                        if tab == .share {
                            NSViewAccessor { view in
                                shareView = view
                            }
                        }
                    }
                })
                .onTapGesture(perform: {
                    action(tab)
                })
                .overlay(alignment: .bottom) {
                    if tab != .privacy {
                        theme.subText(isDark: isDark).opacity(0.1)
                            .frame(height: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(content: {
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.secondaryCard(isDark: isDark))
        })
        .padding(.horizontal, 15)
    }
}

#Preview {
    SettingsView()
}
#endif
