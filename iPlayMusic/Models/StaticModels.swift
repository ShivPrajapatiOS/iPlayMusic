//
//  StaticModels.swift
//  iPlayMusic
//
//  Created by Shiv on 17/07/26.
//

import SwiftUI

enum QueueLyricsSelectionType: String, CaseIterable {
    case lyrics, queue
    
    var title: String {
        switch self {
        case .lyrics: return "Lyrics"
        case .queue: return "Queue"
        }
    }
    
    var icon: String {
        switch self {
        case .lyrics: return "music.pages"
        case .queue: return "music.note.list"
        }
    }
}
