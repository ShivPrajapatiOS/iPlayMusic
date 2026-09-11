//
//  SelectSongSheetView.swift
//  iPlayMusic
//
//  Created by Shiv on 08/09/26.
//

import SwiftUI

struct SelectSongSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @StateObject private var vmNewRelease: NewReleaseViewModel = .shared

    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @State private var selectedSongIDs: Set<String> = []
    let onSongsSelected: ([SongModel]) -> Void
    
    private var selectedSongs: [SongModel] {
        vmNewRelease.newSongs.filter { selectedSongIDs.contains($0.id) }
    }
    
    
    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    ForEach(vmNewRelease.newSongs, id: \.id) { song in
                        let isSelected = selectedSongIDs.contains(song.id)
                        HStack(spacing: 12) {
                            RoundedRectangleWebImageView(url: URL(string: song.thumbnailURL ?? ""))
                                .frame(width: 40, height: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(song.name ?? "Unknown")
                                    .font(.system(size: 13, weight: .regular, design: .default))
                                    .foregroundStyle(theme.text(isDark: isDark))
                                Text(song.artists?.all?.compactMap { $0.name }.joined(separator: ", ") ?? "Unknown")
                                    .font(.system(size: 11, weight: .light, design: .default))
                                    .foregroundStyle(theme.subText(isDark: isDark))
                            }
                            .lineLimit(1)
                            
                            Spacer(minLength: 10)
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 15, height: 15)
                                    .foregroundStyle(theme.theme.primary)
                                    .padding(.trailing)
                            }
                            
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.horizontal, 7.5)
                        .background {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(theme.background(isDark: isDark).opacity(0.5))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(theme.secondaryCard(isDark: isDark), lineWidth: 1)
                                }
                        }
                        .frame(height: 55)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleSelection(for: song)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .top, content: {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10 ,weight: .light, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .frame(width: 22.5, height: 22.5)
                        .background(Circle().fill(theme.subText(isDark: !isDark)))
                }
                
                Spacer(minLength: 10)
                Button {
                    onSongsSelected(selectedSongs)
                    dismiss()
                } label: {
                    Text("Add \(selectedSongIDs.count) Song\(selectedSongIDs.count > 1 ? "s" : "")")
                        .font(.system(size: 10, weight: .medium, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .padding(.init(top: 6, leading: 10, bottom: 6, trailing: 10))
                        .background {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.theme.primary)
                        }
                }
                .disabled(selectedSongIDs.isEmpty)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.horizontal)
        })

    }
    
    private func toggleSelection(for song: SongModel) {
        if selectedSongIDs.contains(song.id) {
            selectedSongIDs.remove(song.id)
        } else {
            selectedSongIDs.insert(song.id)
        }
    }
}

#Preview {
    SelectSongSheetView(onSongsSelected: { _ in })
}
