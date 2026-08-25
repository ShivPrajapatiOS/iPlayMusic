//
//  MusicLanguageView.swift
//  iPlayMusic
//
//  Created by Shiv on 22/07/26.
//

import SwiftUI

enum MusicLanguage: String, CaseIterable, Codable {
    case hindi, english, gujarati, punjabi, haryanvi, rajasthani, sanskrit, bhojpuri, telugu, tamil, marathi, bengali, kannada, malayalam, odia, assamese
    
    var title: String {
        switch self {
        case .hindi: return "हिंदी"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .english: return "English"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .bengali: return "বাংলা"
        case .kannada: return "ಕನ್ನಡ"
        case .bhojpuri: return "भोजपुरी"
        case .malayalam: return "മലയാളം"
        case .sanskrit: return "संस्कृत"
        case .haryanvi: return "हरियानी"
        case .rajasthani: return "राजस्थानी"
        case .odia: return "ଓଡ଼ିଆ"
        case .assamese: return "অসমীজ"
        }
    }
    
    var side: Alignment {
        switch self {
        case .hindi: return .leading
        case .tamil: return .trailing
        case .telugu: return .leading
        case .english: return .trailing
        case .punjabi: return .trailing
        case .marathi: return .leading
        case .gujarati: return .leading
        case .bengali: return .trailing
        case .kannada: return .leading
        case .bhojpuri: return .trailing
        case .malayalam: return .trailing
        case .sanskrit: return .leading
        case .haryanvi: return .leading
        case .rajasthani: return .trailing
        case .odia: return .leading
        case .assamese: return .trailing
        }
    }
    
    var image: String {
        switch self {
        case .hindi: return "ic_arijit_singh"
        case .tamil: return "ic_arijit_singh"
        case .telugu: return "ic_arijit_singh"
        case .english: return "ic_arijit_singh"
        case .punjabi: return "ic_punjabi_artist"
        case .marathi: return "ic_arijit_singh"
        case .gujarati: return "ic_arijit_singh"
        case .bengali: return "ic_arijit_singh"
        case .kannada: return "ic_arijit_singh"
        case .bhojpuri: return "ic_arijit_singh"
        case .malayalam: return "ic_arijit_singh"
        case .sanskrit: return "ic_arijit_singh"
        case .haryanvi: return "ic_hariyanavi_artist"
        case .rajasthani: return "ic_arijit_singh"
        case .odia: return "ic_arijit_singh"
        case .assamese: return "ic_arijit_singh"
        }
    }
}

struct MusicLanguageView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    
    @State private var selectedMusicLanguage: Set<MusicLanguage> = []
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack(alignment: .center) {
                theme.background(isDark: isDark)
                    .blur(radius: appState.isMusicLanguage ? 2.5 : 0)
                    .ignoresSafeArea()
                
                ZStack {
                    ScrollView(.vertical, showsIndicators: false, content: {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]) {
                            ForEach(MusicLanguage.allCases, id: \.self) { language in
                                let isSelected = selectedMusicLanguage.contains(language)
                                ZStack(alignment: .leading) {
                                    VStack {
                                        Text(language.title)
                                            .font(.system(size: 12, weight: .semibold, design: .default))
                                            .foregroundStyle(theme.text(isDark: isDark))
                                        Text(language.rawValue.capitalized)
                                            .font(.system(size: 12, weight: .light, design: .default))
                                            .foregroundStyle(theme.text(isDark: isDark))
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 75)
                                .overlay(alignment: language.side, content: {
                                    Image(language.image)
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(isSelected ? 1 : 0.25)
                                })
                                .overlay(alignment: .topTrailing, content: {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12, weight: .light, design: .default))
                                            .foregroundStyle(theme.theme.accent)
                                            .padding(3)
                                    }
                                })
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(theme.subText(isDark: !isDark))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        toggleSelection(for: language)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInset(edge: .top, content: {
                        VStack(spacing: 4) {
                            Text("What music do you listen to?")
                                .font(.system(size: 13, weight: .semibold, design: .default))
                                .foregroundStyle(theme.text(isDark: isDark))
                            Text("Tap to select one to more")
                                .font(.system(size: 8, weight: .regular, design: .default))
                                .foregroundStyle(theme.subText(isDark: isDark))
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [
                                    theme.secondaryCard(isDark: isDark),
                                    theme.secondaryCard(isDark: isDark),
                                    theme.secondaryCard(isDark: isDark).opacity(0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    })
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 10) {
                            Text("\(selectedMusicLanguage.count) Select \(selectedMusicLanguage.count == 1 ? "" : "ed")")
                                .font(.system(size: 8, weight: .regular, design: .default))
                                .foregroundStyle(theme.subText(isDark: isDark))
                            Button {
                                withAnimation(.bouncy) {
                                    appState.isMusicLanguage = false
                                }
                            } label: {
                                Text("Next")
                                    .font(.system(size: 13, weight: .semibold, design: .default))
                                    .frame(maxWidth: .infinity, minHeight: 35)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(theme.theme.accent))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 30)
                            
                        }
                        .padding(.bottom)
                        .padding(.top, 10)
                    }
                }
                .frame(width: 400, height: 500)
                .background {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(theme.secondaryCard(isDark: isDark))
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea()
        }
        .onAppear {
            loadSavedLanguages()
        }
    }
    
    private func toggleSelection(for language: MusicLanguage) {
        if selectedMusicLanguage.contains(language) {
            selectedMusicLanguage.remove(language)
        } else {
            selectedMusicLanguage.insert(language)
        }
        saveLanguages()
    }
    
    private func saveLanguages() {
        if let encodedData = try? JSONEncoder().encode(selectedMusicLanguage) {
            appState.selectedListenMusicLanguages = encodedData
        }
    }
    
    private func loadSavedLanguages() {
        guard let data = appState.selectedListenMusicLanguages, let decodedLanguages = try? JSONDecoder().decode(Set<MusicLanguage>.self, from: data) else {
            return
        }
        selectedMusicLanguage = decodedLanguages
    }
}

struct DropDownMusicLanguageView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    var body: some View {
        Menu {
            ForEach(MusicLanguage.allCases, id: \.self) { musicLanguage in
                Button {
                    withAnimation(.easeInOut) {
                        appState.musicLanguage = musicLanguage
                    }
                } label: {
                    Label(musicLanguage.title, systemImage: appState.musicLanguage == musicLanguage ? "checkmark" : "music.note")
                }
            }
        } label: {
            HStack {
                Text(appState.musicLanguage.rawValue.capitalized)
                    .font(.system(size: 11, weight: .regular, design: .default))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .regular, design: .default))
            }
            .frame(height: 32.5)
            .padding(.horizontal, 15)
            .foregroundStyle(theme.text(isDark: isDark))
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

#Preview {
    MusicLanguageView()
}
