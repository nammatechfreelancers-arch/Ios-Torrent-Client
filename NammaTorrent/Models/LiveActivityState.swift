// MARK: - LiveActivityState.swift
// Data model for ActivityKit / Dynamic Island Live Activities.

import Foundation
import ActivityKit

/// Attributes that remain constant for the lifetime of a Live Activity.
public struct TorrentActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var torrentName: String
        public var progress: Double          // 0.0 – 1.0
        public var downloadSpeed: Double     // bytes/sec
        public var uploadSpeed: Double       // bytes/sec
        public var eta: TimeInterval         // seconds, -1 = unknown
        public var peerCount: Int
        public var status: String            // TorrentStatus.rawValue
        public var health: Double            // 0.0 – 1.0

        public init(
            torrentName: String,
            progress: Double,
            downloadSpeed: Double,
            uploadSpeed: Double,
            eta: TimeInterval,
            peerCount: Int,
            status: String,
            health: Double
        ) {
            self.torrentName = torrentName
            self.progress = progress
            self.downloadSpeed = downloadSpeed
            self.uploadSpeed = uploadSpeed
            self.eta = eta
            self.peerCount = peerCount
            self.status = status
            self.health = health
        }
    }

    public var torrentID: String   // UUID string — constant for activity lifetime

    public init(torrentID: String) {
        self.torrentID = torrentID
    }
}
