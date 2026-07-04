// BitTorrentProtocol.swift — Constants, extensions, and protocol helpers
import Foundation
import CryptoKit

// MARK: - Protocol Constants
public enum BTProtocol {
    static let pstr = "BitTorrent protocol"
    static let pstrlen: UInt8 = 19
    static let handshakeLength = 68
    static let blockSize = 16_384  // 16 KiB standard block
    static let maxPipelineRequests = 10
    static let keepAliveInterval: TimeInterval = 120
    static let connectionTimeout: TimeInterval = 30
    static let requestTimeout: TimeInterval = 60
    static let maxPeers = 50
    static let port: UInt16 = 6881
}

// MARK: - Extension Bits (reserved bytes in handshake)
public struct ExtensionBits {
    static let dht: UInt8 = 0x01        // byte 7 bit 0
    static let fast: UInt8 = 0x04       // byte 7 bit 2
    static let extension_: UInt8 = 0x10 // byte 5 bit 4 (BEP 10)
}

// MARK: - Peer Wire Message
public struct PeerMessage: Sendable {
    public let type: PeerMessageType
    public let payload: Data

    public init(type: PeerMessageType, payload: Data = Data()) {
        self.type = type
        self.payload = payload
    }

    public var encoded: Data {
        var msg = Data(capacity: 5 + payload.count)
        let length = UInt32(1 + payload.count)
        msg.append(contentsOf: withUnsafeBytes(of: length.bigEndian, Array.init))
        msg.append(type.rawValue)
        msg.append(payload)
        return msg
    }

    // MARK: - Factory methods
    public static func have(pieceIndex: Int) -> PeerMessage {
        var p = Data(4)
        p.writeUInt32(UInt32(pieceIndex), at: 0)
        return PeerMessage(type: .have, payload: p)
    }

    public static func request(index: Int, begin: Int, length: Int) -> PeerMessage {
        var p = Data(12)
        p.writeUInt32(UInt32(index), at: 0)
        p.writeUInt32(UInt32(begin), at: 4)
        p.writeUInt32(UInt32(length), at: 8)
        return PeerMessage(type: .request, payload: p)
    }

    public static func cancel(index: Int, begin: Int, length: Int) -> PeerMessage {
        var p = Data(12)
        p.writeUInt32(UInt32(index), at: 0)
        p.writeUInt32(UInt32(begin), at: 4)
        p.writeUInt32(UInt32(length), at: 8)
        return PeerMessage(type: .cancel, payload: p)
    }

    public static func bitfield(_ bits: Data) -> PeerMessage {
        PeerMessage(type: .bitfield, payload: bits)
    }

    public static var interested: PeerMessage { PeerMessage(type: .interested) }
    public static var notInterested: PeerMessage { PeerMessage(type: .notInterested) }
    public static var choke: PeerMessage { PeerMessage(type: .choke) }
    public static var unchoke: PeerMessage { PeerMessage(type: .unchoke) }
    public static var keepAlive: Data { Data([0, 0, 0, 0]) }
}

// MARK: - Handshake Builder
public enum HandshakeBuilder {
    public static func build(infoHash: Data, peerID: Data, extensionBits: [UInt8] = [0,0,0,0,0,0,0,0]) -> Data {
        var h = Data(capacity: BTProtocol.handshakeLength)
        h.append(BTProtocol.pstrlen)
        h.append(contentsOf: BTProtocol.pstr.utf8)
        h.append(contentsOf: extensionBits)
        h.append(infoHash)
        h.append(peerID)
        return h
    }

    public static func validate(_ data: Data, expectedInfoHash: Data) -> Bool {
        guard data.count >= BTProtocol.handshakeLength else { return false }
        let receivedHash = data[28..<48]
        return receivedHash == expectedInfoHash
    }
}

// MARK: - Peer ID Generator
public enum PeerIDGenerator {
    /// Generates Azureus-style peer ID: -NT0100-<random12bytes>
    public static func generate() -> Data {
        let prefix = "-NT0100-"
        var id = Data(prefix.utf8)
        var random = Data(count: 12)
        random.withUnsafeMutableBytes { _ = SecRandomCopyBytes(kSecRandomDefault, 12, $0.baseAddress!) }
        id.append(random)
        return id
    }
}

// MARK: - Bitfield Helpers
public extension Data {
    func hasPiece(_ index: Int) -> Bool {
        let byte = index / 8
        let bit = 7 - (index % 8)
        guard byte < count else { return false }
        return (self[byte] >> bit) & 1 == 1
    }

    static func bitfield(pieceCount: Int, verifiedPieces: Set<Int>) -> Data {
        let byteCount = (pieceCount + 7) / 8
        var bits = Data(count: byteCount)
        for i in verifiedPieces where i < pieceCount {
            bits[i / 8] |= (0x80 >> (i % 8))
        }
        return bits
    }
}

// MARK: - Data Write Helpers
extension Data {
    mutating func writeUInt32(_ value: UInt32, at offset: Int) {
        let bytes = withUnsafeBytes(of: value.bigEndian, Array.init)
        for (i, b) in bytes.enumerated() { self[offset + i] = b }
    }

    func readUInt32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return UInt32(self[offset]) << 24 | UInt32(self[offset+1]) << 16
             | UInt32(self[offset+2]) << 8  | UInt32(self[offset+3])
    }
}

// MARK: - Info Hash
public enum InfoHashHelper {
    public static func fromHex(_ hex: String) -> Data? {
        guard hex.count == 40 else { return nil }
        var data = Data(capacity: 20)
        var idx = hex.startIndex
        for _ in 0..<20 {
            let next = hex.index(idx, offsetBy: 2)
            guard let byte = UInt8(hex[idx..<next], radix: 16) else { return nil }
            data.append(byte)
            idx = next
        }
        return data
    }

    public static func toHex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
