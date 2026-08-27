//
//  AudioFileManager.swift
//  iPlayMusic
//
//  Created by Shiv on 16/08/26.
//

import Foundation
import SwiftUI
import Combine

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
final class AudioFileManager: NSObject, ObservableObject {
    
    static let shared = AudioFileManager()
    
    /// songId -> progress (0.0 to 1.0). SwiftUI views ise @Published ke
    /// through observe kar sakte hain (progress bar dikhane ke liye).
    @Published private(set) var downloadProgress: [String: Double] = [:]
    
    private let audioFolderName = "DownloadedSongs"
    
    private struct DownloadContext {
        let songId: String
        let destinationURL: URL
        let continuation: CheckedContinuation<URL, Error>
    }
    
    /// taskIdentifier -> context, taaki delegate callbacks me pata chale
    /// ki kaunsa task kis song ka hai.
    private var activeDownloads: [Int: DownloadContext] = [:]
    
    private lazy var session: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    private override init() {
        super.init()
    }
    
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
    
    /// Current progress ek specific song ka (0.0 to 1.0). Agar download
    /// active nahi hai to nil.
    func progress(for songId: String) -> Double? {
        downloadProgress[songId]
    }
    
    // MARK: - Download
    
    /// Remote JioSaavn URL se audio download karke local disk par save karta hai.
    /// Progress `downloadProgress[songId]` ke through live update hota rehta hai.
    ///
    /// Return value: saved fileName jo Realm me `localAudioFileName` field me
    /// store karna hai.
    ///
    /// - Parameters:
    ///   - remoteURL: JioSaavn song ka streaming/download URL (`song.url` ya `song.downloadURL?.url`)
    ///   - songId: Unique song identifier, filename banane ke liye aur progress track karne ke liye use hota hai
    @discardableResult
    func downloadAudio(from remoteURL: URL, songId: String) async throws -> String {
        let fileExtension = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        let fileName = "\(songId).\(fileExtension)"
        let destinationURL = localFileURL(fileName: fileName)
        
        // Agar already downloaded hai to dobara download mat karo
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return fileName
        }
        
        await MainActor.run { downloadProgress[songId] = 0 }
        
        do {
            let finalURL: URL = try await withCheckedThrowingContinuation { continuation in
                let task = session.downloadTask(with: remoteURL)
                activeDownloads[task.taskIdentifier] = DownloadContext(
                    songId: songId,
                    destinationURL: destinationURL,
                    continuation: continuation
                )
                task.resume()
            }
            await MainActor.run { downloadProgress.removeValue(forKey: songId) }
            return finalURL.lastPathComponent
        } catch {
            await MainActor.run { downloadProgress.removeValue(forKey: songId) }
            throw error
        }
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

// MARK: - URLSessionDownloadDelegate

extension AudioFileManager: URLSessionDownloadDelegate {
    
    /// Har chunk aane par call hota hai — yahi se live percentage nikalta hai.
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let context = activeDownloads[downloadTask.taskIdentifier],
              totalBytesExpectedToWrite > 0 else { return }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        Task { @MainActor in
            self.downloadProgress[context.songId] = progress
        }
    }
    
    /// Download poora hone par temp file ko final destination par move karta hai.
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let context = activeDownloads.removeValue(forKey: downloadTask.taskIdentifier) else { return }
        
        do {
            if FileManager.default.fileExists(atPath: context.destinationURL.path) {
                try FileManager.default.removeItem(at: context.destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: context.destinationURL)
            context.continuation.resume(returning: context.destinationURL)
        } catch {
            context.continuation.resume(throwing: error)
        }
    }
    
    /// Network error / cancel hone par continuation ko fail karta hai
    /// (warna await hamesha ke liye latka reh jayega).
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let context = activeDownloads.removeValue(forKey: task.taskIdentifier) else { return }
        context.continuation.resume(throwing: error)
    }
}
