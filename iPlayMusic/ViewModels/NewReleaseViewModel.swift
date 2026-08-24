//
//  NewReleaseViewModel.swift
//  iPlayMusic
//
//  Created by Shiv on 23/08/26.
//

import SwiftUI
import Combine

class NewReleaseViewModel: BaseViewModel {
    
    @Published var newReleases: [ScrapedItem] = []
    @Published var newSongs: [SongModel] = []
    @Published var newAlbums: [AlbumModel] = []
    @Published var newArtists: [ArtistModel] = []
    @Published var newPlaylists: [PlaylistModel] = []
    
    private let service: JioSaavnServiceProtocol
    
    init(service: JioSaavnServiceProtocol = JioSaavnService.shared) {
        self.service = service
    }
    
    func startLoading() {
        Task {
            await runScrape()
            await newRelease()
        }
    }
    
    private func newRelease() async {
        Task {
            await fetchNewSongs()
        }
        Task {
            await fetchNewAlbums()
        }
        Task {
            await fetchNewPlaylists()
        }
    }
    
    private func runScrape() async {
        await execute {
            try await JioSaavnScraper.shared.scrapeNewReleases(language: "Hindi")
        } onSuccess: { result in
            self.newReleases = result
        }
    }
    
    private func fetchNewSongs() async {
        let newSongsLinks: [String] = newReleases.filter { $0.type == "song" }.compactMap { $0.url }

        for link in newSongsLinks {
            await execute {
                try await self.service.getSong(link: link)
            } onSuccess: { result in
                for song in result {
                    self.newSongs.append(song)
                }
            }
        }
    }
    
    private func fetchNewAlbums() async {
        let newAlbumsLinks: [String] = newReleases.filter({ $0.type == "album" }).compactMap({ $0.url })
        
        for link in newAlbumsLinks {
            await execute {
                try await self.service.getAlbum(link: link)
            } onSuccess: { result in
                let artists = AlbumArtistModel(primary: result.artists?.primary?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) }, featured: result.artists?.featured?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) }, all: result.artists?.all?.map { AlbumArtistMini(id: $0.id, name: $0.name, role: $0.role, image: $0.image, type: $0.type, url: $0.url) })
                let newAlbum = AlbumModel(id: result.id, name: result.name, description: result.description, url: result.url, year: result.year, type: result.type, playCount: nil, language: result.language, explicitContent: result.explicitContent, songCount: result.songCount, artists: artists, image: result.image)
                self.newAlbums.append(newAlbum)
            }
        }
    }
    
    private func fetchNewPlaylists() async {
        let newPlaylistsLinks: [String] = newReleases.filter({ $0.type == "playlist" }).compactMap({ $0.url })
        
        for link in newPlaylistsLinks {
            await execute {
                try await self.service.getPlaylist(link: link)
            } onSuccess: { result in
                let newPlaylist = PlaylistModel(id: result.id, name: result.name, type: result.type, image: result.image, url: result.url, songCount: result.songCount, language: result.language, explicitContent: result.explicitContent)
                self.newPlaylists.append(newPlaylist)
            }
        }
    }
}
