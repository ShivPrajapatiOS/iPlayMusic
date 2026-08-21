//
//  Extensions.swift
//  iPlay
//
//  Created by Shiv on 06/09/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif
import Combine
import Foundation
import UniformTypeIdentifiers
import CryptoKit


// MARK: - Date Extension
extension Date {
    var toStringShortMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM, yyyy"
        formatter.locale = .current
        return formatter.string(from: self)
    }
}

// MARK: - Int Extension
extension Int64 {
    func toTimeString() -> String {
        let totalSeconds = self / 1000
        guard totalSeconds > 0 else {
            return "00:00"
        }
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%02lld:%02lld:%02lld", hours, minutes, seconds)
        } else {
            return String(format: "%02lld:%02lld", minutes, seconds)
        }
    }
}


// MARK: - UIImage Extension
#if os(iOS)
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    func dominantColor() -> UIColor? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]) else { return nil }
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        let r = CGFloat(bitmap[0]) / 255.0
        let g = CGFloat(bitmap[1]) / 255.0
        let b = CGFloat(bitmap[2]) / 255.0
        let a = CGFloat(bitmap[3]) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func dominantColorThree() -> (UIColor?, UIColor?, UIColor?) {
            guard let ciImage = CIImage(image: self) else {
                return (nil, nil, nil)
            }

            let context = CIContext(options: [.workingColorSpace: kCFNull!])
            let width = ciImage.extent.width
            let height = ciImage.extent.height

            var results: [UIColor?] = []

            for i in 0..<3 {
                let segmentHeight = height / 3
                let originY = CGFloat(i) * segmentHeight
                let extentVector = CIVector(x: 0, y: originY, z: width, w: segmentHeight)

                guard let filter = CIFilter(name: "CIAreaAverage", parameters: [
                    kCIInputImageKey: ciImage,
                    kCIInputExtentKey: extentVector
                ]) else {
                    results.append(nil)
                    continue
                }

                guard let outputImage = filter.outputImage else {
                    results.append(nil)
                    continue
                }

                var bitmap = [UInt8](repeating: 0, count: 4)
                context.render(outputImage,
                               toBitmap: &bitmap,
                               rowBytes: 4,
                               bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                               format: .RGBA8,
                               colorSpace: nil)

                let r = CGFloat(bitmap[0]) / 255.0
                let g = CGFloat(bitmap[1]) / 255.0
                let b = CGFloat(bitmap[2]) / 255.0
                let a = CGFloat(bitmap[3]) / 255.0

                results.append(UIColor(red: r, green: g, blue: b, alpha: a))
            }

            return (results.count > 0 ? results[0] : nil,
                    results.count > 1 ? results[1] : nil,
                    results.count > 2 ? results[2] : nil)
        }
    
    func applyBlur(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        blurFilter?.setValue(radius, forKey: kCIInputRadiusKey)
        
        guard let outputImage = blurFilter?.outputImage else { return nil }
        
        let context = CIContext(options: nil)
        let cgImage: CGImage? = context.createCGImage(outputImage, from: ciImage.extent)
        
        if cgImage == nil {
            return nil
        } else {
            return UIImage(cgImage: cgImage!)
        }
    }
}
#endif

// MARK: - Color Extension
extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


// MARK: - UTType Extension
extension UTType {
    static var audioTypes: [UTType] {
        return [.mp3, .wav, .audio]
    }
    
    static var videoTypes: [UTType] {
        return [.video, .mpeg2Video, .appleProtectedMPEG4Video, .movie, .mpeg4Movie, UTType(filenameExtension: "mkv") ?? UTType(exportedAs: "org.matroska.mkv")]
    }
}


// MARK: - URL Extension
extension URL {
    func getFileInfo() -> (fileType: String, fileSize: String, created: String, modified: String, accessed: String)? {
        do {
            let resourceKeys: Set<URLResourceKey> = [
                .creationDateKey,
                .contentModificationDateKey,
                .contentAccessDateKey,
                .fileSizeKey,
                .typeIdentifierKey,
            ]
            let resourceValues = try self.resourceValues(forKeys: resourceKeys)
            
            let fileType = resourceValues.typeIdentifier ?? "Unknown"
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(resourceValues.fileSize ?? 0), countStyle: .file)
            let createDate = resourceValues.creationDate?.timeIntervalSince1970 ?? 0
            let modifiedDate = resourceValues.contentModificationDate?.timeIntervalSince1970 ?? 0
            let lastAccessedDate = resourceValues.contentAccessDate?.timeIntervalSince1970 ?? 0
            return (fileType, fileSize, createDate.formatDate, modifiedDate.formatDate, lastAccessedDate.formatDate)
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
}

// MARK: - TimeInterval Extension
extension TimeInterval {
    var formatDate: String {
        let date = Date(timeIntervalSince1970: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func toDisplayTime() -> String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        // %02d ka matlab hai ki agar second 9 hai toh wo "09" dikhayega
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#if os(iOS)
extension UIScreen {
    public var cornerRadius: CGFloat {
        if let radius = UIScreen.main.value(forKey: "_displayCornerRadius") as? CGFloat {
            return radius
        }
        return 0
    }
}
#endif

var isPad: Bool {
#if os(iOS)
    return UIDevice.current.userInterfaceIdiom == .pad
#else
    return false
#endif
}

#if os(macOS)
extension NSWindow {
    func setupAppleMusicStyleTitleBar() {

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        styleMask.insert(.fullSizeContentView)

        guard
            let close = standardWindowButton(.closeButton),
            let mini = standardWindowButton(.miniaturizeButton),
            let zoom = standardWindowButton(.zoomButton)
        else { return }

        close.translatesAutoresizingMaskIntoConstraints = true
        mini.translatesAutoresizingMaskIntoConstraints = true
        zoom.translatesAutoresizingMaskIntoConstraints = true

        let top: CGFloat = 10
        let left: CGFloat = 16

        close.setFrameOrigin(NSPoint(x: left,
                                     y: frame.height - close.frame.height - top))

        mini.setFrameOrigin(NSPoint(x: left + 20,
                                    y: frame.height - mini.frame.height - top))

        zoom.setFrameOrigin(NSPoint(x: left + 40,
                                    y: frame.height - zoom.frame.height - top))
    }
}

struct WindowAccessor: NSViewRepresentable {

    func makeNSView(context: Context) -> NSView {

        let view = NSView()

        DispatchQueue.main.async {

            if let window = view.window {

                window.setupAppleMusicStyleTitleBar()
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {

    }
}
#endif


extension String {
    var sha256: String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 {
                    return
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}



extension View {
#if !os(macOS)
    func enableSwipeBack() -> some View {
        self.onAppear {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first,
               let navController = window.rootViewController?.findNavigationController() {
                
                navController.interactivePopGestureRecognizer?.isEnabled = true
                navController.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
#endif
}

#if !os(macOS)
extension UIViewController {
    func findNavigationController() -> UINavigationController? {
        if let nav = self as? UINavigationController {
            return nav
        }
        for child in children {
            if let nav = child.findNavigationController() {
                return nav
            }
        }
        return nil
    }
}
#endif
