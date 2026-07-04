// StorageService.swift — Persists torrent list and app state to disk
import Foundation

public actor StorageService {
    public static let shared = StorageService()

    private let torrentsURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        torrentsURL = docs.appendingPathComponent("torrents.json")
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Torrent List
    public func saveTorrents(_ torrents: [TorrentModel]) throws {
        let data = try encoder.encode(torrents)
        try data.write(to: torrentsURL, options: .atomic)
    }

    public func loadTorrents() throws -> [TorrentModel] {
        guard FileManager.default.fileExists(atPath: torrentsURL.path) else { return [] }
        let data = try Data(contentsOf: torrentsURL)
        return try decoder.decode([TorrentModel].self, from: data)
    }

    // MARK: - Download Directory
    public func downloadsDirectory() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func torrentDirectory(for infoHash: String) -> URL {
        let dir = downloadsDirectory().appendingPathComponent(infoHash, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Torrent File Cache
    public func saveTorrentFile(_ data: Data, infoHash: String) throws {
        let url = downloadsDirectory().appendingPathComponent("\(infoHash).torrent")
        try data.write(to: url, options: .atomic)
    }

    public func torrentFileURL(for infoHash: String) -> URL? {
        let url = downloadsDirectory().appendingPathComponent("\(infoHash).torrent")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Disk Usage
    public func diskUsage(for infoHash: String) -> Int64 {
        let dir = torrentDirectory(for: infoHash)
        guard let enumerator = FileManager.default.enumerator(
            at: dir, includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }

    public func deleteTorrentData(infoHash: String) throws {
        let dir = torrentDirectory(for: infoHash)
        if FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.removeItem(at: dir)
        }
    }
}
