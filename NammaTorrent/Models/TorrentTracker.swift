// MARK: - TorrentTracker.swift
import Foundation

public enum TrackerStatus: String, Codable, Sendable {
    case working    = "Working"
    case updating   = "Updating"
    case notWorking = "Not Working"
    case disabled   = "Disabled"
    case unknown    = "Unknown"
}

public struct TorrentTracker: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var url: String
    public var status: TrackerStatus
    public var seeders: Int
    public var leechers: Int
    public var peers: Int
    public var lastAnnounce: Date?
    public var nextAnnounce: Date?
    public var message: String?
    public var tier: Int

    public init(
        id: UUID = UUID(),
        url: String,
        status: TrackerStatus = .unknown,
        seeders: Int = 0,
        leechers: Int = 0,
        peers: Int = 0,
        lastAnnounce: Date? = nil,
        nextAnnounce: Date? = nil,
        message: String? = nil,
        tier: Int = 0
    ) {
        self.id = id
        self.url = url
        self.status = status
        self.seeders = seeders
        self.leechers = leechers
        self.peers = peers
        self.lastAnnounce = lastAnnounce
        self.nextAnnounce = nextAnnounce
        self.message = message
        self.tier = tier
    }
}
