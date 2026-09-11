//
//  WindowManager.swift
//  iPlayMusic
//
//  Created by Shiv on 01/08/26.
//

import SwiftUI

#if os(macOS)
struct NSViewAccessor: NSViewRepresentable {

    var callback: (NSView) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            callback(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) { }
}

enum NewWindowType: String {
    case settings, purchase, signIn, web
    
    var size: CGSize {
        switch self {
        case .settings:
            return CGSize(width: 390, height: 350)
        case .purchase:
            return CGSize(width: 800, height: 500)
        case .signIn:
            return CGSize(width: 394, height: 500)
        case .web:
            return CGSize(width: 800, height: 500)
        }
    }
}

class WindowManager: NSObject, NSWindowDelegate {
    
    static let shared = WindowManager()
    
    private(set) var windows: [NewWindowType: NSWindow] = [:]
    
    func openWindow(id: NewWindowType, title: String, view: AnyView) {
        if let window = windows[id] {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: id.size.width, height: id.size.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        if id == .purchase {
            window.styleMask.remove(.miniaturizable)
        }

        window.center()
        window.title = title
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("\(id.rawValue)-window")

        window.contentView = NSHostingView(rootView: view)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask.insert(.fullSizeContentView)

        window.makeKeyAndOrderFront(nil)
        windows[id] = window
    }
    
    func closeWindow(id: NewWindowType) {
        guard let window = windows[id] else { return }
        window.close()
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }
        
        if let key = windows.first(where: { $0.value == closedWindow })?.key {
            windows[key] = nil
        }
    }
}
#endif
