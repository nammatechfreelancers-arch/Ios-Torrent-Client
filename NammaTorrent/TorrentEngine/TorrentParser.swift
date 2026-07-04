// MARK: - TorrentParser.swift
// Parses .torrent (metainfo) files into TorrentModel.

import Foundation
import CryptoKit

public enum TorrentParserError: Error, LocalizedError {
    case invalidData
    case missingInfoDict
    case missingName
    case missingPieceLength
    case missingPieces

    public var errorDescription: String? {
        switch self {
        case .invalidData:       return "Invalid .torrent file data"
        case .missingInfoDict:   return "Missing 'info' dictionary"
        case .missingName:       return "Missing torrent name"
        case .missingPieceLength: return "Missing piece length"
        case .missingPieces:     return "Missing pieces hash data"
        }
    }
}

public struct ParsedTorrent: Sendable {
    public let infoHash: String
    public let name: String
    public let totalSize: Int64
    public let pieceLength: Int
    public let pieceCount: Int
    public let files: [TorrentFile]
    public let trackers: [TorrentTracker]
    public let isPrivate: Bool
    public let comment: String?
    public let createdBy: String?
    public let creationDate: Date?
}

public enum TorrentParser {
    public static func parse(data: Data) throws -> ParsedTorrent {
        let root = try BDecoder.decode(data)
        guard let dict = root.dictValue else { throw TorrentParserError.invalidData }
        guard let info = dict["info"]?.dictValue else { throw TorrentParserError.missingInfoDict }
        guard let name = info["name"]?.stringValue else { throw TorrentParserError.missingName }
        guard let pieceLength = info["piece length"]?.intValue else { throw TorrentParserError.missingPieceLength }
        guard let piecesData = info["pieces"]?.dataValue else { throw TorrentParserError.missingPieces }

        // Compute info hash (SHA1 of bencoded info dict)
        let infoEncoded = BEncoder.encode(.dictionary(info))
        let infoHash = Insecure.SHA1.hash(data: infoEncoded).map { String(format: "%02x", $0) }.joined()

        // Parse files
        var files: [TorrentFile] = []
        var totalSize: Int64 = 0

        if let fileList = info["files"]?.listValue {
            // Multi-file torrent
            for (idx, fileEntry) in fileList.enumerated() {
                guard let fileDict = fileEntry.dictValue,
                      let length = fileDict["length"]?.intValue,
                      let pathList = fileDict["path"]?.listValue else { continue }
                let pathComponents = pathList.compactMap { $0.stringValue }
                let filePath = ([name] + pathComponents).joined(separator: "/")
                let fileName = pathComponents.last ?? "unknown"
                files.append(TorrentFile(index: idx, name: fileName, path: filePath, size: length))
                totalSize += length
            }
        } else if let length = info["length"]?.intValue {
            // Single-file torrent
            files.append(TorrentFile(index: 0, name: name, path: name, size: length))
            totalSize = length
        }

        let pieceCount = Int(ceil(Double(totalSize) / Double(pieceLength)))

        // Parse trackers
        var trackers: [TorrentTracker] = []
        if let announce = dict["announce"]?.stringValue {
            trackers.append(TorrentTracker(url: announce, tier: 0))
        }
        if let announceList = dict["announce-list"]?.listValue {
            for (tier, tierEntry) in announceList.enumerated() {
                if let tierList = tierEntry.listValue {
                    for entry in tierList {
                        if let url = entry.stringValue, !trackers.contains(where: { $0.url == url }) {
                            trackers.append(TorrentTracker(url: url, tier: tier))
                        }
                    }
                }
            }
        }

        let isPrivate = info["private"]?.intValue == 1
        let comment = dict["comment"]?.stringValue
        let createdBy = dict["created by"]?.stringValue
        let creationDate: Date? = dict["creation date"]?.intValue.map { Date(timeIntervalSince1970: TimeInterval($0)) }

        return ParsedTorrent(
            infoHash: infoHash,
            name: name,
            totalSize: totalSize,
            pieceLength: Int(pieceLength),
            pieceCount: pieceCount,
            files: files,
            trackers: trackers,
            isPrivate: isPrivate,
            comment: comment,
            createdBy: createdBy,
            creationDate: creationDate
        )
    }
}
