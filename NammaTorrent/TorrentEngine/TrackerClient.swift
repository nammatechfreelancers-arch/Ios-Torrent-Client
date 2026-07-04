// MARK: - TrackerClient.swift
// HTTP and UDP tracker announce/scrape client.

import Foundation

public enum TrackerError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case trackerFailure(String)
    case unsupportedProtocol

    public var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid tracker URL"
        case .networkError(let e):     return "Network error: \(e.localizedDescription)"
        case .invalidResponse:         return "Invalid tracker response"
        case .trackerFailure(let msg): return "Tracker error: \(msg)"
        case .unsupportedProtocol:     return "Unsupported tracker protocol"
        }
    }
}

public struct TrackerResponse: Sendable {
    public let interval: Int
    public let minInterval: Int?
    public let seeders: Int
    public let leechers: Int
    public let peers: [(ip: String, port: Int)]
    public let warningMessage: String?
}

public actor TrackerClient {
    private let session: URLSession
    private let peerID: Data
    private let port: Int = 6881

    public init(peerID: Data) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.peerID = peerID
    }

    // MARK: - HTTP Tracker Announce
    public func announce(
        trackerURL: String,
        infoHash: Data,
        downloaded: Int64,
        uploaded: Int64,
        left: Int64,
        event: String = "started"
    ) async throws -> TrackerResponse {
        guard var components = URLComponents(string: trackerURL) else { throw TrackerError.invalidURL }

        let peerIDStr = peerID.map { String(format: "%c", $0) }.joined()
        let infoHashEscaped = infoHash.map { String(format: "%%%02X", $0) }.joined()

        components.percentEncodedQuery = [
            "info_hash=\(infoHashEscaped)",
            "peer_id=\(peerIDStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
            "port=\(port)",
            "uploaded=\(uploaded)",
            "downloaded=\(downloaded)",
            "left=\(left)",
            "compact=1",
            "event=\(event)",
            "numwant=50"
        ].joined(separator: "&")

        guard let url = components.url else { throw TrackerError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TrackerError.invalidResponse
        }

        return try parseHTTPResponse(data: data)
    }

    // MARK: - Parse HTTP Tracker Response
    private func parseHTTPResponse(data: Data) throws -> TrackerResponse {
        let decoded = try BDecoder.decode(data)
        guard let dict = decoded.dictValue else { throw TrackerError.invalidResponse }

        if let failure = dict["failure reason"]?.stringValue {
            throw TrackerError.trackerFailure(failure)
        }

        let interval = Int(dict["interval"]?.intValue ?? 1800)
        let minInterval = dict["min interval"]?.intValue.map { Int($0) }
        let seeders = Int(dict["complete"]?.intValue ?? 0)
        let leechers = Int(dict["incomplete"]?.intValue ?? 0)
        let warning = dict["warning message"]?.stringValue

        var peers: [(ip: String, port: Int)] = []

        if let compactPeers = dict["peers"]?.dataValue {
            // Compact format: 6 bytes per peer (4 IP + 2 port)
            var i = 0
            while i + 6 <= compactPeers.count {
                let ip = "\(compactPeers[i]).\(compactPeers[i+1]).\(compactPeers[i+2]).\(compactPeers[i+3])"
                let port = Int(compactPeers[i+4]) << 8 | Int(compactPeers[i+5])
                peers.append((ip: ip, port: port))
                i += 6
            }
        } else if let peerList = dict["peers"]?.listValue {
            // Dictionary format
            for peer in peerList {
                if let peerDict = peer.dictValue,
                   let ip = peerDict["ip"]?.stringValue,
                   let port = peerDict["port"]?.intValue {
                    peers.append((ip: ip, port: Int(port)))
                }
            }
        }

        return TrackerResponse(
            interval: interval,
            minInterval: minInterval,
            seeders: seeders,
            leechers: leechers,
            peers: peers,
            warningMessage: warning
        )
    }
}
