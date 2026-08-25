//
//  NewReleaseViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 23/08/26.
//

import SwiftUI
import Combine

@MainActor
final class NewReleaseViewModel: BaseViewModel {
    
    @Published var newReleases: [ScrapedItem] = []
    @Published var newSongs: [SongModel] = []
    @Published var newAlbums: [AlbumModel] = []
    @Published var newArtists: [ArtistModel] = []
    @Published var newPlaylists: [PlaylistModel] = []
    
    @Published var isNewLoading: Bool = false
    
    private let service: JioSaavnServiceProtocol
    
    init(service: JioSaavnServiceProtocol? = nil) {
        self.service = service ?? JioSaavnService.shared
    }
    
    func startLoading() {
        Task {
            isNewLoading = true
            await runScrape()
            await fetchAllNewReleases()
            isNewLoading = false
        }
    }
    
    private func runScrape() async {
        await execute {
            try await JioSaavnScraper.shared.scrapeNewReleases(language: StateManager.shared.musicLanguage.rawValue)
        } onSuccess: { result in
            self.newReleases = result
        }
    }
    
    private func fetchAllNewReleases() async {
        
        await withTaskGroup(of: Void.self) { group in
            
            group.addTask {
                await self.fetchNewSongs()
            }
            
            group.addTask {
                await self.fetchNewAlbums()
            }
            
            group.addTask {
                await self.fetchNewPlaylists()
            }
            
            group.addTask {
                await self.getNewArtists()
            }
        }
    }
    
    private func fetchNewSongs() async {
        newSongs.removeAll()
        let links = newReleases.filter { $0.type == "song" }.compactMap { $0.url }
        
        await withTaskGroup(of: [SongModel].self) { group in
            for link in links {
                group.addTask {
                    do {
                        return try await self.service.getSong(link: link)
                    } catch {
                        print("Song API Error:", error)
                        return []
                    }
                }
            }
            
            for await songs in group {
                await MainActor.run {
                    self.newSongs.append(contentsOf: songs)
                }
            }
        }
    }
    
    private func fetchNewAlbums() async {
        newAlbums.removeAll()
        let links = newReleases.filter { $0.type == "album" }.compactMap { $0.url }
        
        await withTaskGroup(of: AlbumModel?.self) { group in
            for link in links {
                group.addTask {
                    do {
                        let result = try await self.service.getAlbum(link: link)
                        let artists = AlbumArtistModel(primary: result.artists?.primary?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) }, featured: result.artists?.featured?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) }, all: result.artists?.all?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) })
                        
                        return AlbumModel(id: result.id, name: result.name, description: result.description, url: result.url, year: result.year, type: result.type, playCount: nil, language: result.language, explicitContent: result.explicitContent, songCount: result.songCount, artists: artists, image: result.image)
                    } catch {
                        print("Album API Error:", error)
                        return nil
                    }
                }
            }
            
            for await album in group {
                if let album {
                    await MainActor.run {
                        self.newAlbums.append(album)
                    }
                }
            }
        }
    }
    
    private func fetchNewPlaylists() async {
        newPlaylists.removeAll()
        let links = newReleases.filter { $0.type == "playlist" }.compactMap { $0.url }
        
        await withTaskGroup(of: PlaylistModel?.self) { group in
            for link in links {
                group.addTask {
                    do {
                        let result = try await self.service.getPlaylist(link: link)
                        return PlaylistModel(id: result.id,  name: result.name, type: result.type, image: result.image, url: result.url, songCount: result.songCount, language: result.language, explicitContent: result.explicitContent)
                    } catch {
                        print("Playlist API Error:", error)
                        return nil
                    }
                }
            }
            
            for await playlist in group {
                if let playlist {
                    await MainActor.run {
                        self.newPlaylists.append(playlist)
                    }
                }
            }
        }
    }
    
    private func getNewArtists() async {
        newArtists.removeAll()
        let links = newReleases.filter { $0.type == "artist" }.compactMap { $0.url }
        
        await withTaskGroup(of: ArtistModel?.self) { group in
            for link in links {
                group.addTask {
                    do {
                        let result = try await self.service.getArtist(link: link)
                        return ArtistModel(id: result.id, name: result.name, role: "Singer", image: result.image, type: result.type, url: result.url)
                    } catch {
                        print("Artist API Error:", error)
                        return nil
                    }
                }
            }
            
            for await artist in group {
                if let artist {
                    await MainActor.run {
                        self.newArtists.append(artist)
                    }
                }
            }
        }
    }
}
