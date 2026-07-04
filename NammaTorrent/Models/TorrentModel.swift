// MARK: - TorrentModel.swift
// Core data model representing a single torrent.

import Foundation
import Combine

// MARK: - Torrent Status
public enum TorrentStatus: String, Codable, CaseIterable, Sendable {
    case queued       = "Queued"
    case downloading  = "Downloading"
    case seeding      = "Seeding"
    case paused       = "Paused"
    case stopped      = "Stopped"
    case checking     = "Checking"
    case error        = "Error"
    case completed    = "Completed"
    case metadata     = "Fetching Metadata"

    var systemImage: String {
        switch self {
        case .queued:      return "clock"
        case .downloading: return "arrow.down.circle.fill"
        case .seeding:     return "arrow.up.circle.fill"
        case .paused:      return "pause.circle.fill"
        case .stopped:     return "stop.circle.fill"
        case .checking:    return "magnifyingglass.circle.fill"
        case .error:       return "exclamationmark.circle.fill"
        case .completed:   return "checkmark.circle.fill"
        case .metadata:    return "antenna.radiowaves.left.and.right"
        }
    }
}

// MARK: - Torrent Priority
public enum TorrentPriority: Int, Codable, CaseIterable, Sendable {
    case low    = 0
    case normal = 1
    case high   = 2
}

// MARK: - TorrentModel
public struct TorrentModel: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var infoHash: String
    public var name: String
    public var magnetLink: String?
    public var torrentFilePath: String?
    public var status: TorrentStatus
    public var priority: TorrentPriority

    // Size
    public var totalSize: Int64
    public var downloadedSize: Int64
    public var uploadedSize: Int64

    // Speed (bytes/sec) — not persisted, computed at runtime
    public var downloadSpeed: Double
    public var uploadSpeed: Double

    // Progress 0.0 – 1.0
    public var progress: Double

    // Peers & Seeds
    public var seedCount: Int
    public var peerCount: Int
    public var leecherCount: Int

    // ETA in seconds (-1 = unknown)
    public var eta: TimeInterval

    // Dates
    public var addedDate: Date
    public var completedDate: Date?
    public var lastActiveDate: Date

    // Storage
    public var savePath: String
    public var files: [TorrentFile]

    // Health 0.0 – 1.0
    public var health: Double

    // Flags
    public var isSequential: Bool
    public var isPrivate: Bool
    public var hasMetadata: Bool

    // Trackers
    public var trackers: [TorrentTracker]

    // Error
    public var errorMessage: String?

    // Thumbnail (first image file path if any)
    public var thumbnailPath: String?

    public init(
        id: UUID = UUID(),
        infoHash: String,
        name: String,
        magnetLink: String? = nil,
        torrentFilePath: String? = nil,
        status: TorrentStatus = .queued,
        priority: TorrentPriority = .normal,
        totalSize: Int64 = 0,
        downloadedSize: Int64 = 0,
        uploadedSize: Int64 = 0,
        downloadSpeed: Double = 0,
        uploadSpeed: Double = 0,
        progress: Double = 0,
        seedCount: Int = 0,
        peerCount: Int = 0,
        leecherCount: Int = 0,
        eta: TimeInterval = -1,
        addedDate: Date = Date(),
        completedDate: Date? = nil,
        lastActiveDate: Date = Date(),
        savePath: String = "",
        files: [TorrentFile] = [],
        health: Double = 0,
        isSequential: Bool = false,
        isPrivate: Bool = false,
        hasMetadata: Bool = false,
        trackers: [TorrentTracker] = [],
        errorMessage: String? = nil,
        thumbnailPath: String? = nil
    ) {
        self.id = id
        self.infoHash = infoHash
        self.name = name
        self.magnetLink = magnetLink
        self.torrentFilePath = torrentFilePath
        self.status = status
        self.priority = priority
        self.totalSize = totalSize
        self.downloadedSize = downloadedSize
        self.uploadedSize = uploadedSize
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.progress = progress
        self.seedCount = seedCount
        self.peerCount = peerCount
        self.leecherCount = leecherCount
        self.eta = eta
        self.addedDate = addedDate
        self.completedDate = completedDate
        self.lastActiveDate = lastActiveDate
        self.savePath = savePath
        self.files = files
        self.health = health
        self.isSequential = isSequential
        self.isPrivate = isPrivate
        self.hasMetadata = hasMetadata
        self.trackers = trackers
        self.errorMessage = errorMessage
        self.thumbnailPath = thumbnailPath
    }

    // Coding keys — exclude runtime-only fields from persistence
    enum CodingKeys: String, CodingKey {
        case id, infoHash, name, magnetLink, torrentFilePath, status, priority
        case totalSize, downloadedSize, uploadedSize
        case progress, seedCount, peerCount, leecherCount, eta
        case addedDate, completedDate, lastActiveDate
        case savePath, files, health, isSequential, isPrivate, hasMetadata
        case trackers, errorMessage, thumbnailPath
        // downloadSpeed and uploadSpeed are NOT persisted
    }

    public var remainingSize: Int64 { max(0, totalSize - downloadedSize) }
    public var isActive: Bool { status == .downloading || status == .seeding }
    public var isFinished: Bool { status == .completed || progress >= 1.0 }
    public var ratio: Double { uploadedSize > 0 && downloadedSize > 0 ? Double(uploadedSize) / Double(downloadedSize) : 0 }
}
