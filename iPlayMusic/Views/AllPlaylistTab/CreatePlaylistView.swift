//
//  CreatePlaylistView.swift
//  iPlayMusic
//
//  Created by Shiv on 11/08/26.
//

import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#else
import UIKit
#endif

#if os(macOS)
    typealias PlatformImage = NSImage
#else
    typealias PlatformImage = UIImage
#endif

struct CreatePlaylistView: View {
    @Environment(\.colorScheme) private var systemScheme
    @StateObject private var theme: ThemeManager = .shared
    @StateObject private var appState: StateManager = .shared
    @ObservedObject var vmMyPlaylist: MyPlaylistRealmViewModel
    
    private var isDark: Bool {
        if theme.themeMode == .system {
            return systemScheme == .dark
        }
        return theme.themeMode == .dark
    }
    
    @Binding var showCreatePlaylist: Bool
    
    @State private var isFileImporterPresented: Bool = false
        
    var body: some View {
#if !os(macOS)
        ZStack {
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
        ZStack {
            VStack(spacing: 50) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(theme.secondaryCard(isDark: isDark))
                    .frame(width: 150, height: 150)
                    .overlay(content: {
                        if let data = vmMyPlaylist.imageData, let decodeImage = NSImage(data: data) {
                            Image(nsImage: decodeImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .light, design: .default))
                                .foregroundStyle(theme.text(isDark: isDark))
                        }
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(content: {
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(theme.border(isDark: isDark), lineWidth: 1)
                    })
                    .shadow(color: theme.border(isDark: isDark), radius: 1, x: 0, y: 0)
                    .onTapGesture {
                        isFileImporterPresented.toggle()
                    }
                
                VStack(spacing: 15) {
                    TextField("Playlist Title", text: $vmMyPlaylist.txtNewPlaylist)
                        .font(.system(size: 12, weight: .regular, design: .default))
                        .foregroundStyle(theme.text(isDark: isDark))
                        .textFieldStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .padding(.horizontal, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(vmMyPlaylist.txtNewPlaylist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.subText(isDark: isDark).opacity(0.25) : theme.theme.primary, lineWidth: 1)
                                }
                        }
                    
                    TextEditor(text: Binding(get: { vmMyPlaylist.txtDescription ?? "" }, set: { vmMyPlaylist.txtDescription = $0 }))
                        .cornerRadius(5)
                        .textEditorStyle(.plain)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 7)
                        .frame(height: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.clear)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke((vmMyPlaylist.txtDescription ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.subText(isDark: isDark).opacity(0.25) : theme.theme.primary, lineWidth: 1)
                                }
                        }
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .top) {
                Text("New Playlist")
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundStyle(theme.text(isDark: isDark))
                    .frame(maxWidth: .infinity)
                    .frame(height: 35, alignment: .top)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button {
                        showCreatePlaylist.toggle()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(.red)
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal)
                            .background {
                                Capsule()
                                    .fill(.red.opacity(0.25))
                            }
                    }
                    Spacer(minLength: 20)
                    Button {
                        if let playlist = vmMyPlaylist.isUpdatePlaylist {
                            Task {
                                do {
                                    vmMyPlaylist.isLoading = true
                                    let updatePlaylist = try await vmMyPlaylist.updatePlaylist(playlistId: playlist._id, name: vmMyPlaylist.txtNewPlaylist, description: vmMyPlaylist.txtDescription, imageData: vmMyPlaylist.imageData)
                                    vmMyPlaylist.errorMessage = nil
                                    vmMyPlaylist.isLoading = false
                                    vmMyPlaylist.isUpdatePlaylist = nil
                                    showCreatePlaylist.toggle()
                                    let tableReference = try await FirebaseSyncManager.shared.updateMyPlaylistSync(updatePlaylist)
                                    print("this Object isSynced: \(tableReference)")
                                    try await FirebaseSyncManager.shared.isSync(object: updatePlaylist)
                                } catch {
                                    vmMyPlaylist.isLoading = false
                                    vmMyPlaylist.errorMessage = error.localizedDescription
                                }
                            }
                        } else {
                            Task {
                                do {
                                    vmMyPlaylist.isLoading = true
                                    let newPlaylist = try await vmMyPlaylist.addNewPlaylist(name: vmMyPlaylist.txtNewPlaylist, description: vmMyPlaylist.txtDescription, imageData: vmMyPlaylist.imageData)
                                    vmMyPlaylist.errorMessage = nil
                                    vmMyPlaylist.isLoading = false
                                    showCreatePlaylist.toggle()
                                    let tableReference = try await FirebaseSyncManager.shared.addMyPlaylistSync(newPlaylist)
                                    print("this Object isSynced: \(tableReference)")
                                    try await FirebaseSyncManager.shared.isSync(object: newPlaylist)
                                } catch {
                                    vmMyPlaylist.isLoading = false
                                    vmMyPlaylist.errorMessage = error.localizedDescription
                                }
                            }
                        }
                    } label: {
                        Text("Create")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundStyle(Color("#FFFFFF"))
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal)
                            .background {
                                Capsule()
                                    .fill(theme.theme.accent)
                            }
                    }
                    .disabled(vmMyPlaylist.txtNewPlaylist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 27)
            }
            .padding()
        }
        .frame(maxWidth: 300)
        .frame(height: 475)
        .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.image], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                
                let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                let compressedData: Data? = NSImage(contentsOf: fileURL).flatMap {
                    ImageCompressor.compress($0)
                }
                withAnimation {
                    vmMyPlaylist.imageData = compressedData
                }
                //                if let data = try? Data(contentsOf: fileURL) {
                //                    withAnimation {
                //                        vmMyPlaylist.imageData = compressedData
                //                    }
                //                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
        .onAppear {
            if let playlist = vmMyPlaylist.isUpdatePlaylist {
                vmMyPlaylist.txtNewPlaylist = playlist.name
                vmMyPlaylist.txtDescription = playlist.desc
                vmMyPlaylist.imageData = playlist.imageData
            }
        }
#endif
    }
}

#Preview {
    CreatePlaylistView(vmMyPlaylist: .init(), showCreatePlaylist: .constant(false))
}
