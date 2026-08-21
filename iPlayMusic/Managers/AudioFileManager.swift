//
//  AudioFileManager.swift
//  iPlayMusic
//
//  Created by Shiv on 16/08/26.
//

import Foundation

/// Singleton jo song audio files ko app ki private Documents directory ke
/// andar "DownloadedSongs" folder me download/save/delete/check karta hai.
///
/// IMPORTANT: Realm me hamesha sirf `fileName` store karo, poora absolute
/// path NAHI — sandbox container path reinstall/update ke sath change ho
/// sakta hai. Full path hamesha `localFileURL(fileName:)` se runtime par
/// dobara banao.
///
/// Ye audio bytes KABHI Firebase par nahi jaate — sirf "downloaded hai ya
/// nahi" (isDownloaded flag) sync hota hai. Actual audio har device khud
/// JioSaavn ke URL se download karta hai (free, quota-safe).
final class AudioFileManager {
    
    static let shared = AudioFileManager()
    private init() {}
    
    private let audioFolderName = "DownloadedSongs"
    
    private var audioDirectory: URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folderURL = documentsURL.appendingPathComponent(audioFolderName, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        return folderURL
    }
    
    // MARK: - Path Helpers
    
    func localFileURL(fileName: String) -> URL {
        audioDirectory.appendingPathComponent(fileName)
    }
    
    /// Kya diya gaya song already local disk par downloaded hai.
    func fileExists(fileName: String?) -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        return FileManager.default.fileExists(atPath: localFileURL(fileName: fileName).path)
    }
    
    // MARK: - Download
    
    /// Remote JioSaavn URL se audio download karke local disk par save karta hai.
    /// Return value: saved fileName jo Realm me `localAudioFileName` field me
    /// store karna hai.
    ///
    /// - Parameters:
    ///   - remoteURL: JioSaavn song ka streaming/download URL (`song.url` ya `song.downloadURL?.url`)
    ///   - songId: Unique song identifier, filename banane ke liye use hota hai
    @discardableResult
    func downloadAudio(from remoteURL: URL, songId: String) async throws -> String {
        let fileExtension = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        let fileName = "\(songId).\(fileExtension)"
        let destinationURL = localFileURL(fileName: fileName)
        
        // Agar already downloaded hai to dobara download mat karo
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return fileName
        }
        
        let (tempURL, response) = try await URLSession.shared.download(from: remoteURL)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        // Agar koi purani incomplete file pehle se hai to hata do
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        return fileName
    }
    
    // MARK: - Delete
    
    /// Downloaded audio ko disk se hata deta hai (jab user "remove download" kare).
    @discardableResult
    func deleteAudio(fileName: String?) -> Bool {
        guard let fileName, !fileName.isEmpty else { return false }
        let url = localFileURL(fileName: fileName)
        
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            print("AudioFileManager: delete error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Storage Info (optional, "Downloads" settings screen ke liye)
    
    /// Total space jo downloaded songs le rahe hain (bytes me) — settings/storage screen ke liye useful.
    func totalDownloadedSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        return files.reduce(Int64(0)) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return total + Int64(size)
        }
    }
}

