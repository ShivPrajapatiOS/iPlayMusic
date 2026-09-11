//
//  DecoderType.swift
//  iPlayMusic
//
//  Created by Shiv on 06/09/26.
//

import SwiftUI

enum DecoderType: String, CaseIterable, Hashable {
    case hwDecoder = "HW Decoder"
    case swDecoder = "SW Decoder"
    
    var codecOptions: [AnyHashable: Any] {
        var options: [AnyHashable: Any] = [
            "network-caching": 2000,
            "live-caching": 1000,
            "file-caching": 3000,
            ":rtsp-tcp": true,
            ":rtp-timeout": 10000,
            "clock-jitter": 500,
            "drop-late-frames": true,
            "skip-frames": true
        ]
        
        switch self {
        case .hwDecoder:
            // Audio ke liye "hardware decoding" generally meaningless hai —
            // VLC audio codecs (mp3/aac) already lightweight hain, CPU decode hi hota hai
            options["audio-desync"] = 0
        case .swDecoder:
            options["avcodec-threads"] = 2
            options["avcodec-fast"] = true
        }
        
        return options
    }
}
