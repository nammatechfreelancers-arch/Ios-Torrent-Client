// NativeFileManager.swift — File operations for downloaded content
import Foundation
import QuickLook

public actor NativeFileManager {
    public static let shared = NativeFileManager()
    private init() {}

    private let fm = FileManager.default

    // MARK: - Downloads Root
    public func downloadsRoot() -> URL {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Downloads")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - List Files
    public func listFiles(at url: URL) -> [URL] {
        (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [
            .fileSizeKey, .creationDateKey, .isDirectoryKey
        ], options: .skipsHiddenFiles)) ?? []
    }

    // MARK: - File Info
    public func fileSize(at url: URL) -> Int64 {
        Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    public func isDirectory(at url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    // MARK: - Operations
    public func move(from source: URL, to destination: URL) throws {
        try fm.moveItem(at: source, to: destination)
    }

    public func delete(at url: URL) throws {
        try fm.removeItem(at: url)
    }

    public func createDirectory(at url: URL) throws {
        try fm.createDirectory(at: url, withIntermediateDirectories: true)
    }

    // MARK: - Share URL (for UIActivityViewController)
    public func shareURL(for url: URL) -> URL { url }

    // MARK: - Total Downloads Size
    public func totalDownloadsSize() -> Int64 {
        let root = downloadsRoot()
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return total
    }
}
