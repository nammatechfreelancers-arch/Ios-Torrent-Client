// MARK: - MagnetParser.swift
// Parses magnet URIs into structured data.

import Foundation
import CryptoKit

public struct MagnetInfo: Sendable {
    public let infoHash: String       // hex string
    public let infoHashData: Data
    public let displayName: String
    public let trackers: [String]
    public let webSeeds: [String]

    public init(infoHash: String, infoHashData: Data, displayName: String, trackers: [String], webSeeds: [String]) {
        self.infoHash = infoHash
        self.infoHashData = infoHashData
        self.displayName = displayName
        self.trackers = trackers
        self.webSeeds = webSeeds
    }
}

public enum MagnetParserError: Error, LocalizedError {
    case invalidScheme
    case missingInfoHash
    case invalidInfoHash(String)

    public var errorDescription: String? {
        switch self {
        case .invalidScheme:           return "Not a magnet URI"
        case .missingInfoHash:         return "Magnet URI missing xt (info hash)"
        case .invalidInfoHash(let s):  return "Invalid info hash: \(s)"
        }
    }
}

public enum MagnetParser {
    public static func parse(_ uri: String) throws -> MagnetInfo {
        guard uri.lowercased().hasPrefix("magnet:?") else { throw MagnetParserError.invalidScheme }

        let queryString = String(uri.dropFirst("magnet:?".count))
        var components: [String: [String]] = [:]

        for pair in queryString.components(separatedBy: "&") {
            let parts = pair.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            let key = parts[0]
            let value = parts[1...].joined(separator: "=").removingPercentEncoding ?? parts[1...].joined(separator: "=")
            components[key, default: []].append(value)
        }

        // Extract info hash from xt=urn:btih:<hash>
        guard let xtValues = components["xt"], let xt = xtValues.first else {
            throw MagnetParserError.missingInfoHash
        }

        let infoHashHex: String
        let infoHashData: Data

        if xt.lowercased().hasPrefix("urn:btih:") {
            let raw = String(xt.dropFirst("urn:btih:".count))
            if raw.count == 40 {
                // Hex-encoded SHA1
                infoHashHex = raw.lowercased()
                guard let d = Data(hexString: infoHashHex) else { throw MagnetParserError.invalidInfoHash(raw) }
                infoHashData = d
            } else if raw.count == 32 {
                // Base32-encoded SHA1
                guard let d = Data(base32Encoded: raw) else { throw MagnetParserError.invalidInfoHash(raw) }
                infoHashData = d
                infoHashHex = d.hexString
            } else {
                throw MagnetParserError.invalidInfoHash(raw)
            }
        } else {
            throw MagnetParserError.missingInfoHash
        }

        let displayName = components["dn"]?.first ?? infoHashHex
        let trackers = components["tr"] ?? []
        let webSeeds = components["ws"] ?? []

        return MagnetInfo(
            infoHash: infoHashHex,
            infoHashData: infoHashData,
            displayName: displayName,
            trackers: trackers,
            webSeeds: webSeeds
        )
    }
}

// MARK: - Data hex helpers
extension Data {
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count % 2 == 0 else { return nil }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        self = data
    }

    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    // Minimal Base32 decoder (RFC 4648, no padding required)
    init?(base32Encoded string: String) {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let upper = string.uppercased()
        var bits = 0
        var bitsCount = 0
        var result = Data()
        for char in upper {
            guard let val = alphabet.firstIndex(of: char) else { return nil }
            let idx = alphabet.distance(from: alphabet.startIndex, to: val)
            bits = (bits << 5) | idx
            bitsCount += 5
            if bitsCount >= 8 {
                bitsCount -= 8
                result.append(UInt8((bits >> bitsCount) & 0xFF))
            }
        }
        self = result
    }
}
