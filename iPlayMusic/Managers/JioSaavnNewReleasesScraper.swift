//
//  JioSaavnNewReleasesScraper.swift
//
//  Swift port of test-new-releases.js (v2)
//  - No external HTML parsing library (no SwiftSoup). Uses NSRegularExpression,
//    same as the original script's regex-based href matching, plus a simple
//    regex to grab an <a>...</a> tag's inner text (tags stripped).
//  - Fetches https://www.jiosaavn.com/new-releases/<language>
//  - Extracts song / album / playlist(featured) / artist links
//  - Saves the result as JSON to Documents/scraped-output.json
//
//  Drop this file into your Xcode project. Call it like:
//
//      Task {
//          do {
//              let items = try await JioSaavnScraper.shared.scrapeNewReleases(language: "hindi")
//              print("Got \(items.count) items")
//          } catch {
//              print("Scrape failed: \(error)")
//          }
//      }
//

import Foundation

// MARK: - Model

struct ScrapedItem: Codable, Identifiable, Hashable {
    var id: String       // the trailing slug from the URL (same field name as JS `id`)
    let type: String      // "song" | "album" | "playlist" | "artist"
    let title: String
    let url: String
}

// MARK: - Errors

enum JioSaavnScraperError: LocalizedError {
    case badStatus(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):
            return "Response OK nahi hai — status code: \(code)"
        case .decodingFailed:
            return "HTML ko string me decode nahi kar paya"
        }
    }
}

// MARK: - Scraper

final class JioSaavnScraper {

    static let shared = JioSaavnScraper()
    private init() {}

    // Same TYPE_PATTERNS as the JS version.
    // NOTE: NSRegularExpression doesn't support JS-style negated char class inline like [^/]+
    // differently — the syntax is the same in ICU regex, so these translate 1:1.
    private let typePatterns: [(type: String, pattern: String)] = [
        ("song",     #"/song/[^/]+/([^/"]+)"#),
        ("album",    #"/album/[^/]+/([^/"]+)"#),
        ("playlist", #"/featured/[^/]+/([^/"]+)"#),
        ("artist",   #"/artist/[^/]+/([^/"]+)"#),
    ]

    /// Fetches the new-releases page for a language, extracts song/album/playlist/artist
    /// links, dedupes them, and writes the result to Documents/scraped-output.json.
    /// Returns the parsed items.
    @discardableResult
    func scrapeNewReleases(language: String = "hindi") async throws -> [ScrapedItem] {
        let urlString = "https://www.jiosaavn.com/new-releases/\(language)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        print("\n[1] Fetching: \(urlString)\n")

        var request = URLRequest(url: url)
        // Same headers as the JS script — real-browser UA, warna JioSaavn block/redirect kar deta hai
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[2] Status: \(status)")
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw JioSaavnScraperError.badStatus(status)
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw JioSaavnScraperError.decodingFailed
        }
        print("[3] HTML length: \(html.count) chars\n")

        let results = extractLinks(from: html)

        // Breakdown by type, same as JS `counts`
        var counts: [String: Int] = [:]
        for r in results { counts[r.type, default: 0] += 1 }

        print("[4] Total unique links found: \(results.count)")
        print("[5] Breakdown by type: \(counts)\n")

        print("[6] ALL results:\n")
        for (i, r) in results.enumerated() {
            print("\(i + 1). [\(r.type)] \(r.title)")
            print("   id: \(r.id)")
            print("   url: \(r.url)\n")
        }

        try save(results)

        return results
    }

    // MARK: - Parsing

    /// Pure-regex equivalent of the JS `$("a[href]").each(...)` loop.
    /// Step 1: find every `<a ...href="...">inner html</a>` block.
    /// Step 2: match href against the type patterns (song/album/playlist/artist).
    /// Step 3: strip tags from the inner html to get the visible text (≈ cheerio's `.text()`).
    private func extractLinks(from html: String) -> [ScrapedItem] {
        var results: [ScrapedItem] = []
        var seen = Set<String>()

        // Matches <a ... href="...">...</a>, non-greedy, across the whole anchor tag.
        // .dotMatchesLineSeparators so multi-line anchor contents are captured too.
        guard let anchorRegex = try? NSRegularExpression(
            pattern: #"<a\s+[^>]*href="([^"]+)"[^>]*>(.*?)</a>"#,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else {
            return results
        }

        let nsHtml = html as NSString
        let anchorMatches = anchorRegex.matches(in: html, range: NSRange(location: 0, length: nsHtml.length))

        for anchorMatch in anchorMatches {
            guard anchorMatch.numberOfRanges >= 3 else { continue }
            let href = nsHtml.substring(with: anchorMatch.range(at: 1))
            let innerHTML = nsHtml.substring(with: anchorMatch.range(at: 2))

            for (type, pattern) in typePatterns {
                guard let typeRegex = try? NSRegularExpression(pattern: pattern) else { continue }
                let hrefNS = href as NSString
                guard let m = typeRegex.firstMatch(in: href, range: NSRange(location: 0, length: hrefNS.length)),
                      m.numberOfRanges >= 2 else { continue }

                let id = hrefNS.substring(with: m.range(at: 1))
                let title = stripTags(innerHTML).trimmingCharacters(in: .whitespacesAndNewlines)
                if title.isEmpty { continue }

                let key = "\(type)-\(id)"
                if seen.contains(key) { continue }
                seen.insert(key)

                let fullURL = href.hasPrefix("http") ? href : "https://www.jiosaavn.com\(href)"
                results.append(ScrapedItem(id: id, type: type, title: title, url: fullURL))
                break // ek href sirf ek type match karega, same as JS
            }
        }

        return results
    }

    /// Removes any nested HTML tags from a fragment, leaving just the text (rough `.text()` equivalent).
    private func stripTags(_ fragment: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
            return fragment
        }
        let range = NSRange(location: 0, length: (fragment as NSString).length)
        let stripped = regex.stringByReplacingMatches(in: fragment, range: range, withTemplate: "")
        // Collapse whitespace/newlines like cheerio's text() roughly does
        return stripped.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    // MARK: - Saving

    private func save(_ items: [ScrapedItem]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(items)

        let documentsURL = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let fileURL = documentsURL.appendingPathComponent("scraped-output.json")

        try jsonData.write(to: fileURL, options: .atomic)
        print("\n💾 Saved to \(fileURL.path) (\(items.count) items)")
    }
}

// MARK: - Optional: minimal SwiftUI screen to test it

#if canImport(SwiftUI)
import SwiftUI

struct JioSaavnScraperTestView: View {
    @State private var language = "hindi"
    @State private var items: [ScrapedItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("language (e.g. hindi, tamil)", text: $language)
                        .textFieldStyle(.roundedBorder)
                    Button(isLoading ? "..." : "Scrape") {
                        runScrape()
                    }
                    .disabled(isLoading)
                }
                .padding()

                if let errorMessage {
                    Text(errorMessage).foregroundColor(.red).padding(.horizontal)
                }

                List(items) { item in
                    VStack(alignment: .leading) {
                        Text("[\(item.type)] \(item.title)").font(.headline)
                        Text(item.url).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("JioSaavn New Releases")
        }
    }

    private func runScrape() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let result = try await JioSaavnScraper.shared.scrapeNewReleases(language: language)
                await MainActor.run {
                    self.items = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
#endif
