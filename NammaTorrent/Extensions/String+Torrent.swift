// String+Torrent.swift — String helpers for torrent data
import Foundation

public extension String {
    var isMagnetLink: Bool { hasPrefix("magnet:?") }
    var isTorrentFile: Bool { lowercased().hasSuffix(".torrent") }

    var infoHashFromMagnet: String? {
        guard isMagnetLink,
              let range = range(of: "xt=urn:btih:") else { return nil }
        let start = index(range.upperBound, offsetBy: 0)
        let end = self[start...].firstIndex(of: "&") ?? endIndex
        let hash = String(self[start..<end])
        return hash.count == 40 ? hash.lowercased() : nil
    }

    var truncated: String {
        count > 40 ? String(prefix(37)) + "..." : self
    }

    func percentEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
