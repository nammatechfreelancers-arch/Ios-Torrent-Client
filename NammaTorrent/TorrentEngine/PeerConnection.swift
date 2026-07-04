// MARK: - PeerConnection.swift
// Manages a single TCP peer connection using the BitTorrent peer wire protocol.

import Foundation
import Network

// MARK: - Peer Wire Message Types
public enum PeerMessageType: UInt8 {
    case choke          = 0
    case unchoke        = 1
    case interested     = 2
    case notInterested  = 3
    case have           = 4
    case bitfield       = 5
    case request        = 6
    case piece          = 7
    case cancel         = 8
    case port           = 9  // DHT
    case handshake      = 255 // synthetic
}

public enum PeerConnectionError: Error {
    case handshakeFailed
    case connectionFailed
    case invalidMessage
    case timeout
    case disconnected
}

// MARK: - PeerConnection Actor
public actor PeerConnection {
    public let peerID: String
    public let ip: String
    public let port: Int
    private let infoHash: Data
    private let localPeerID: Data

    private var connection: NWConnection?
    private var isConnected: Bool = false
    private var amChoking: Bool = true
    private var amInterested: Bool = false
    private var peerChoking: Bool = true
    private var peerInterested: Bool = false
    private var peerBitfield: Data = Data()

    // Callbacks
    public var onPieceReceived: ((Int, Int, Data) -> Void)?
    public var onDisconnected: (() -> Void)?
    public var onHave: ((Int) -> Void)?

    // Setter methods for external configuration (actor isolation)
    public func setOnPieceReceived(_ handler: @escaping (Int, Int, Data) -> Void) {
        onPieceReceived = handler
    }
    public func setOnDisconnected(_ handler: @escaping () -> Void) {
        onDisconnected = handler
    }
    public func setOnHave(_ handler: @escaping (Int) -> Void) {
        onHave = handler
    }

    public init(ip: String, port: Int, infoHash: Data, localPeerID: Data) {
        self.peerID = "\(ip):\(port)"
        self.ip = ip
        self.port = port
        self.infoHash = infoHash
        self.localPeerID = localPeerID
    }

    // MARK: - Connect
    public func connect() async throws {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(ip),
            port: NWEndpoint.Port(integerLiteral: UInt16(port))
        )
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        let conn = NWConnection(to: endpoint, using: params)
        self.connection = conn

        return try await withCheckedThrowingContinuation { continuation in
            conn.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                switch state {
                case .ready:
                    Task { await self.performHandshake(continuation: continuation) }
                case .failed(let error):
                    continuation.resume(throwing: error)
                case .cancelled:
                    continuation.resume(throwing: PeerConnectionError.disconnected)
                default:
                    break
                }
            }
            conn.start(queue: .global(qos: .utility))
        }
    }

    // MARK: - Handshake
    private func performHandshake(continuation: CheckedContinuation<Void, Error>) {
        // BitTorrent handshake: <pstrlen><pstr><reserved><info_hash><peer_id>
        var handshake = Data()
        handshake.append(19)
        handshake.append(contentsOf: "BitTorrent protocol".utf8)
        handshake.append(contentsOf: [0,0,0,0,0,0,0,0]) // reserved
        handshake.append(infoHash)
        handshake.append(localPeerID)

        connection?.send(content: handshake, completion: .contentProcessed { [weak self] error in
            guard let self else { return }
            if let error {
                continuation.resume(throwing: error)
                return
            }
            Task { await self.receiveHandshakeResponse(continuation: continuation) }
        })
    }

    private func receiveHandshakeResponse(continuation: CheckedContinuation<Void, Error>) {
        // Handshake response is 68 bytes
        connection?.receive(minimumIncompleteLength: 68, maximumLength: 68) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let error {
                continuation.resume(throwing: error)
                return
            }
            guard let data, data.count >= 68 else {
                continuation.resume(throwing: PeerConnectionError.handshakeFailed)
                return
            }
            // Verify info hash at bytes 28–48
            let receivedHash = Data(data[28..<48])
            Task {
                guard await self.matchesInfoHash(receivedHash) else {
                    continuation.resume(throwing: PeerConnectionError.handshakeFailed)
                    return
                }
                await self.setConnected(true)
                continuation.resume()
                await self.startReceiveLoop()
            }
        }
    }

    private func setConnected(_ value: Bool) { isConnected = value }
    private func matchesInfoHash(_ receivedHash: Data) -> Bool { receivedHash == infoHash }

    // MARK: - Message Loop
    private func startReceiveLoop() {
        receiveNextMessage()
    }

    private func receiveNextMessage() {
        // Read 4-byte length prefix
        guard let connection else { return }
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, _, error in
            guard let self, error == nil, let data else { return }
            let length = Int(data[0]) << 24 | Int(data[1]) << 16 | Int(data[2]) << 8 | Int(data[3])
            if length == 0 {
                // Keep-alive
                Task { await self.receiveNextMessage() }
                return
            }
            connection.receive(minimumIncompleteLength: length, maximumLength: length) { [weak self] msgData, _, _, error in
                guard let self, error == nil, let msgData else { return }
                Task {
                    await self.handleMessage(msgData)
                    await self.receiveNextMessage()
                }
            }
        }
    }

    private func handleMessage(_ data: Data) {
        guard let typeRaw = data.first, let type = PeerMessageType(rawValue: typeRaw) else { return }
        let payload = data.dropFirst()

        switch type {
        case .unchoke:
            peerChoking = false
        case .choke:
            peerChoking = true
        case .interested:
            peerInterested = true
        case .notInterested:
            peerInterested = false
        case .have:
            guard payload.count >= 4 else { return }
            let index = Int(payload[0]) << 24 | Int(payload[1]) << 16 | Int(payload[2]) << 8 | Int(payload[3])
            onHave?(index)
        case .bitfield:
            peerBitfield = Data(payload)
        case .piece:
            guard payload.count >= 8 else { return }
            let index = Int(payload[0]) << 24 | Int(payload[1]) << 16 | Int(payload[2]) << 8 | Int(payload[3])
            let begin = Int(payload[4]) << 24 | Int(payload[5]) << 16 | Int(payload[6]) << 8 | Int(payload[7])
            let block = Data(payload.dropFirst(8))
            onPieceReceived?(index, begin, block)
        default:
            break
        }
    }

    // MARK: - Send Messages
    public func sendInterested() {
        sendMessage(type: .interested, payload: Data())
    }

    public func sendRequest(pieceIndex: Int, begin: Int, length: Int) {
        var payload = Data(capacity: 12)
        payload.append(contentsOf: withUnsafeBytes(of: UInt32(pieceIndex).bigEndian, Array.init))
        payload.append(contentsOf: withUnsafeBytes(of: UInt32(begin).bigEndian, Array.init))
        payload.append(contentsOf: withUnsafeBytes(of: UInt32(length).bigEndian, Array.init))
        sendMessage(type: .request, payload: payload)
    }

    private func sendMessage(type: PeerMessageType, payload: Data) {
        var msg = Data(capacity: 5 + payload.count)
        let length = UInt32(1 + payload.count)
        msg.append(contentsOf: withUnsafeBytes(of: length.bigEndian, Array.init))
        msg.append(type.rawValue)
        msg.append(payload)
        connection?.send(content: msg, completion: .idempotent)
    }

    public func disconnect() {
        connection?.cancel()
        isConnected = false
        onDisconnected?()
    }

    public var availablePieces: Set<Int> {
        var result = Set<Int>()
        for (byteIdx, byte) in peerBitfield.enumerated() {
            for bit in 0..<8 {
                if byte & (0x80 >> bit) != 0 {
                    result.insert(byteIdx * 8 + bit)
                }
            }
        }
        return result
    }
}
