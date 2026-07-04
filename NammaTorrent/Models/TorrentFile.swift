// MARK: - TorrentFile.swift
import Foundation

public enum FilePriority: Int, Codable, CaseIterable, Sendable {
    case skip   = 0
    case low    = 1
    case normal = 4
    case high   = 7
}

public struct TorrentFile: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var index: Int
    public var name: String
    public var path: String          // relative path within torrent
    public var size: Int64
    public var downloadedSize: Int64
    public var progress: Double
    public var priority: FilePriority
    public var mimeType: String?

    public init(
        id: UUID = UUID(),
        index: Int,
        name: String,
        path: String,
        size: Int64,
        downloadedSize: Int64 = 0,
        progress: Double = 0,
        priority: FilePriority = .normal,
        mimeType: String? = nil
    ) {
        self.id = id
        self.index = index
        self.name = name
        self.path = path
        self.size = size
        self.downloadedSize = downloadedSize
        self.progress = progress
        self.priority = priority
        self.mimeType = mimeType
    }

    public var fileExtension: String { URL(fileURLWithPath: name).pathExtension.lowercased() }

    public var systemImage: String {
        switch fileExtension {
        case "mp4", "mkv", "avi", "mov", "m4v": return "film"
        case "mp3", "flac", "aac", "wav", "m4a": return "music.note"
        case "jpg", "jpeg", "png", "gif", "webp", "heic": return "photo"
        case "pdf": return "doc.richtext"
        case "zip", "rar", "7z", "tar", "gz": return "archivebox"
        case "epub", "mobi": return "book"
        case "txt", "md": return "doc.text"
        default: return "doc"
        }
    }
}
