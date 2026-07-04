// MARK: - DownloadStats.swift
import Foundation

/// Snapshot of engine-wide download statistics.
public struct DownloadStats: Sendable {
    public var totalDownloadSpeed: Double   // bytes/sec
    public var totalUploadSpeed: Double     // bytes/sec
    public var totalDownloaded: Int64       // bytes this session
    public var totalUploaded: Int64         // bytes this session
    public var activeTorrents: Int
    public var pausedTorrents: Int
    public var completedTorrents: Int
    public var storageUsed: Int64           // bytes
    public var freeStorage: Int64           // bytes

    public init(
        totalDownloadSpeed: Double = 0,
        totalUploadSpeed: Double = 0,
        totalDownloaded: Int64 = 0,
        totalUploaded: Int64 = 0,
        activeTorrents: Int = 0,
        pausedTorrents: Int = 0,
        completedTorrents: Int = 0,
        storageUsed: Int64 = 0,
        freeStorage: Int64 = 0
    ) {
        self.totalDownloadSpeed = totalDownloadSpeed
        self.totalUploadSpeed = totalUploadSpeed
        self.totalDownloaded = totalDownloaded
        self.totalUploaded = totalUploaded
        self.activeTorrents = activeTorrents
        self.pausedTorrents = pausedTorrents
        self.completedTorrents = completedTorrents
        self.storageUsed = storageUsed
        self.freeStorage = freeStorage
    }
}

/// Speed history sample for graph rendering.
public struct SpeedSample: Identifiable, Sendable {
    public let id: UUID = UUID()
    public let timestamp: Date
    public let downloadSpeed: Double
    public let uploadSpeed: Double

    public init(timestamp: Date = Date(), downloadSpeed: Double, uploadSpeed: Double) {
        self.timestamp = timestamp
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
    }
}
