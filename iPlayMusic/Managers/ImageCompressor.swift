//
//  ImageCompressor.swift
//  iPlayMusic
//
//  Created by Shiv on 12/08/26.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Playlist cover image ko ek chhote thumbnail size me resize + JPEG compress
/// karta hai, taaki us image ko Realm ke `Data` field me seedha store kiya
/// ja sake aur wahi field Firestore me Blob ke roop me sync ho jaaye —
/// bina Firebase Storage (paid) use kiye.
///
/// Typical result: 300x300 max dimension + 0.6 quality par image
/// roughly 50KB-150KB ke beech rehti hai, jo Firestore ke 1MB per-document
/// limit me aaram se fit ho jaati hai.
enum ImageCompressor {
    
#if os(macOS)
    static func compress(_ image: NSImage, maxDimension: CGFloat = 300, quality: CGFloat = 0.6) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        guard let tiffData = resized.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
    
    private static func resize(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let originalSize = image.size
        // Agar image pehle se hi chhoti hai to upscale mat karo (min(..., 1))
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1)
        let newSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }
#else
    static func compress(_ image: UIImage, maxDimension: CGFloat = 300, quality: CGFloat = 0.6) -> Data? {
        let resized = resize(image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }
    
    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1)
        let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
#endif
}
