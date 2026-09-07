//
//  PlaybackSource.swift
//  iPlayMusic
//
//  Created by Shiv on 06/09/26.
//

import SwiftUI
import Foundation

enum PlaybackSource {
    case songs
    case playlist(PlaylistDetailsModel)
    case album(AlbumDetailsModel)
    case artist(ArtistDetailsModel)
    
    var id: String? {
        switch self {
        case .songs: return nil
        case .playlist(let p): return p.id
        case .album(let a): return a.id
        case .artist(let ar): return ar.id
        }
    }
    
    var title: String? {
        switch self {
        case .songs: return nil
        case .playlist(let p): return p.name
        case .album(let a): return a.name
        case .artist(let ar): return ar.name
        }
    }
}

extension PlaybackSource: Equatable {
    static func == (lhs: PlaybackSource, rhs: PlaybackSource) -> Bool {
        switch (lhs, rhs) {
        case (.songs, .songs):
            return true
        case (.playlist(let l), .playlist(let r)):
            return l.id == r.id
        case (.album(let l), .album(let r)):
            return l.id == r.id
        case (.artist(let l), .artist(let r)):
            return l.id == r.id
        default:
            return false
        }
    }
}
