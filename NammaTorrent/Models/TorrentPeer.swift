// MARK: - TorrentPeer.swift
import Foundation

public enum PeerSource: String, Codable, Sendable {
    case dht, pex, tracker, lsd, incoming
}

public struct TorrentPeer: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var ip: String
    public var port: Int
    public var clientName: String
    public var downloadSpeed: Double   // bytes/sec from this peer
    public var uploadSpeed: Double     // bytes/sec to this peer
    public var progress: Double        // peer's download progress 0–1
    public var source: PeerSource
    public var isEncrypted: Bool
    public var country: String?

    public init(
        id: UUID = UUID(),
        ip: String,
        port: Int,
        clientName: String = "Unknown",
        downloadSpeed: Double = 0,
        uploadSpeed: Double = 0,
        progress: Double = 0,
        source: PeerSource = .tracker,
        isEncrypted: Bool = false,
        country: String? = nil
    ) {
        self.id = id
        self.ip = ip
        self.port = port
        self.clientName = clientName
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
        self.progress = progress
        self.source = source
        self.isEncrypted = isEncrypted
        self.country = country
    }

    public var address: String { "\(ip):\(port)" }
}
