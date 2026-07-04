// URL+Torrent.swift
import Foundation

public extension URL {
    var isMagnetLink: Bool { scheme == "magnet" }
    var isTorrentFile: Bool { pathExtension.lowercased() == "torrent" }

    var fileSize: Int64 {
        Int64((try? resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
    }

    var fileName: String { lastPathComponent }

    var fileSizeFormatted: String { Formatters.fileSize(fileSize) }
}
