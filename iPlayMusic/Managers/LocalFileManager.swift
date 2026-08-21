//
//  LocalFileManager.swift
//  iPlayMusic
//
//  Created by Shiv on 11/08/26.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Singleton jo app ki private Documents directory ke andar
/// "PlaylistImages" folder me images ko save/retrieve/delete/update karta hai.
///
/// IMPORTANT: Realm me hamesha sirf `fileName` (e.g. "ABCD1234.png") store karo,
/// poora absolute path NAHI, kyunki sandbox container path har app
/// reinstall/update ke sath change ho sakta hai. Full path hum runtime par
/// `retrieveImageURL(fileName:)` se dobara bana lenge.
final class LocalFileManager {
    
    static let shared = LocalFileManager()
    private init() {}
    
    private let imagesFolderName = "PlaylistImages"
    
    /// App ki Documents/PlaylistImages directory. Agar exist nahi karti to create kar deta hai.
    private var imagesDirectory: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsURL.appendingPathComponent(imagesFolderName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                print("LocalFileManager: folder create karne me error: \(error.localizedDescription)")
            }
        }
        return folderURL
    }
    
    // MARK: - Save New Image
    
#if os(macOS)
    /// Naya image save karta hai aur us image ka fileName return karta hai (Realm me store karne ke liye).
    @discardableResult
    func saveImage(_ image: NSImage, fileName: String = UUID().uuidString) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("LocalFileManager: NSImage ko PNG data me convert nahi kar paya")
            return nil
        }
        return write(data: pngData, fileName: fileName)
    }
#else
    /// Naya image save karta hai aur us image ka fileName return karta hai (Realm me store karne ke liye).
    @discardableResult
    func saveImage(_ image: UIImage, fileName: String = UUID().uuidString) -> String? {
        guard let pngData = image.pngData() else {
            print("LocalFileManager: UIImage ko PNG data me convert nahi kar paya")
            return nil
        }
        return write(data: pngData, fileName: fileName)
    }
#endif
    
    /// Common write helper — fileName ke sath ".png" extension jod kar likhta hai.
    private func write(data: Data, fileName: String) -> String? {
        let finalName = fileName.hasSuffix(".png") ? fileName : "\(fileName).png"
        let fileURL = imagesDirectory.appendingPathComponent(finalName)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return finalName
        } catch {
            print("LocalFileManager: image save karne me error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Retrieve Image
    
    /// Sirf fileName se full file URL banata hai (display ke liye AsyncImage/Image me use karo).
    func retrieveImageURL(fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        return imagesDirectory.appendingPathComponent(fileName)
    }
    
#if os(macOS)
    func retrieveImage(fileName: String?) -> NSImage? {
        guard let url = retrieveImageURL(fileName: fileName),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }
#else
    func retrieveImage(fileName: String?) -> UIImage? {
        guard let url = retrieveImageURL(fileName: fileName),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
#endif
    
    // MARK: - Delete Image
    
    /// Diye gaye fileName wali image ko disk se delete karta hai (agar exist karti hai).
    @discardableResult
    func deleteImage(fileName: String?) -> Bool {
        guard let fileName, !fileName.isEmpty,
              let url = retrieveImageURL(fileName: fileName),
              FileManager.default.fileExists(atPath: url.path) else { return false }
        
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("LocalFileManager: image delete karne me error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Update Image (old delete + new save)
    
#if os(macOS)
    /// Purani image (agar hai) delete karta hai aur nayi image save karke uska fileName return karta hai.
    @discardableResult
    func updateImage(oldFileName: String?, newImage: NSImage) -> String? {
        if let oldFileName, !oldFileName.isEmpty {
            deleteImage(fileName: oldFileName)
        }
        return saveImage(newImage)
    }
#else
    /// Purani image (agar hai) delete karta hai aur nayi image save karke uska fileName return karta hai.
    @discardableResult
    func updateImage(oldFileName: String?, newImage: UIImage) -> String? {
        if let oldFileName, !oldFileName.isEmpty {
            deleteImage(fileName: oldFileName)
        }
        return saveImage(newImage)
    }
#endif
}
