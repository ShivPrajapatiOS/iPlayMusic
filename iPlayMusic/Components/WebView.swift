//
//  WebView.swift
//  iPlayMusic
//
//  Created by Shiv on 01/08/26.
//

import SwiftUI
import WebKit

struct WebPageView: View {
    @Binding var url: String
    var isPresented: Bool = false
    var closeAction: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            WebView(url: URL(string: url)!)
                .ignoresSafeArea()
        }
        .safeAreaInset(edge: .top) {
            if isPresented {
                Rectangle().fill(.clear)
                    .frame(height: 50)
                    .overlay(alignment: .leading) {
                        Button {
                            closeAction?()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(Color("#999999"))
                                .frame(width: 35, height: 35)
                                .background(Capsule().fill(.ultraThinMaterial))
                        }
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    }
            }
        }
    }
}

struct WebView: PlatformViewRepresentable {
    let url: URL

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
    #endif

    #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
    #endif
}


#if os(macOS)
// MARK: - WebView (NSViewRepresentable)
struct MacWebView: NSViewRepresentable {
    let htmlFileName: String // e.g. "index" (.html extension mat likho)
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        
        // ✅ Read-only — right click menu disable
        webView.allowsMagnification = true // Pinch zoom allow
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        loadHTMLFile(in: webView)
    }
    
    private func loadHTMLFile(in webView: WKWebView) {
        guard let url = Bundle.main.url(
            forResource: htmlFileName,
            withExtension: "html"
        ) else {
            print("❌ '\(htmlFileName).html' bundle mein nahi mila")
            return
        }
        
        // ✅ loadFileURL use karo — local CSS/images/JS bhi load honge
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    
    // MARK: - Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        // ✅ External links browser mein kholna — WebView mein nahi
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ HTML load ho gaya")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ Load failed: \(error.localizedDescription)")
        }
    }
}
#endif
