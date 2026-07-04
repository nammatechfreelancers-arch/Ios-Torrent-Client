// TorrentEngine.swift — Central actor orchestrating all torrent operations
import Foundation
import Network

// MARK: - Engine Errors
public enum TorrentEngineError: Error, LocalizedError {
    case invalidInfoHash
    case noMetadata
    case storageFailure(String)
    case alreadyExists

    public var errorDescription: String? {
        switch self {
        case .invalidInfoHash:       return "Invalid info hash"
        case .noMetadata:            return "Metadata not yet available"
        case .storageFailure(let m): return "Storage error: \(m)"
        case .alreadyExists:         return "Torrent already added"
        }
    }
}

// MARK: - Engine Delegate
@MainActor
public protocol TorrentEngineDelegate: AnyObject, Sendable {
    func engineDidUpdateTorrent(id: UUID)
    func engineDidCompleteTorrent(id: UUID)
    func engineDidFailTorrent(id: UUID, error: Error)
}

// MARK: - Per-torrent runtime state
private final class TorrentSession: @unchecked Sendable {
    let torrentID: UUID
    let infoHash: Data
    let infoHashHex: String
    let pieceManager: PieceManager
    let trackerClient: TrackerClient
    let dhtNode: DHTNode
    var peers: [String: PeerConnection] = [:]
    var isRunning = false
    let downloadPath: URL
    var totalDownloaded: Int64 = 0
    var totalUploaded: Int64 = 0

    init(torrentID: UUID, infoHash: Data, infoHashHex: String,
         pieceManager: PieceManager, downloadPath: URL, peerID: Data) {
        self.torrentID = torrentID
        self.infoHash = infoHash
        self.infoHashHex = infoHashHex
        self.pieceManager = pieceManager
        self.downloadPath = downloadPath
        self.trackerClient = TrackerClient(peerID: peerID)
        self.dhtNode = DHTNode(port: Int(BTProtocol.port))
    }
}

// MARK: - TorrentEngine
public actor TorrentEngine {
    public static let shared = TorrentEngine()

    private var sessions: [UUID: TorrentSession] = [:]
    private let localPeerID: Data = PeerIDGenerator.generate()
    private var statsTimerTask: Task<Void, Never>?

    public weak var delegate: (any TorrentEngineDelegate)?

    private init() {}

    // MARK: - Add Torrent
    public func addTorrent(
        id: UUID,
        infoHash: String,
        pieceCount: Int,
        pieceLength: Int,
        totalSize: Int64,
        pieceHashes: [Data],
        savePath: URL
    ) async throws {
        guard sessions[id] == nil else { throw TorrentEngineError.alreadyExists }
        guard let hashData = InfoHashHelper.fromHex(infoHash) else { throw TorrentEngineError.invalidInfoHash }

        let pm = PieceManager(
            pieceCount: pieceCount,
            pieceLength: pieceLength,
            totalSize: totalSize,
            pieceHashes: pieceHashes
        )

        // Restore piece state if saved
        let stateURL = savePath.appendingPathComponent("\(infoHash).pieces")
        if let stateData = try? Data(contentsOf: stateURL) {
            await pm.restoreStates(from: stateData)
        }

        let session = TorrentSession(
            torrentID: id,
            infoHash: hashData,
            infoHashHex: infoHash,
            pieceManager: pm,
            downloadPath: savePath,
            peerID: localPeerID
        )
        sessions[id] = session
    }

    // MARK: - Start / Resume
    public func start(id: UUID, trackerURLs: [String]) async {
        guard let session = sessions[id] else { return }
        session.isRunning = true

        let pm = session.pieceManager
        let downloaded = await pm.verifiedCount
        let pieceLen = pm.pieceLength
        let total = pm.totalSize
        let left = total > 0 ? (total - Int64(downloaded * pieceLen)) : Int64.max

        // Filter to HTTP/HTTPS trackers only (UDP not yet implemented)
        let httpTrackers = trackerURLs.filter { $0.hasPrefix("http") }

        // Tracker announce
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in httpTrackers {
                    group.addTask {
                        if let response = try? await session.trackerClient.announce(
                            trackerURL: url,
                            infoHash: session.infoHash,
                            downloaded: session.totalDownloaded,
                            uploaded: session.totalUploaded,
                            left: left,
                            event: "started"
                        ) {
                            let peers = response.peers.map {
                                TorrentPeer(ip: $0.ip, port: $0.port, source: .tracker)
                            }
                            await self.connectToPeers(peers, session: session)
                        }
                    }
                }
            }
        }

        // DHT — bootstrap first, then query after a short delay
        Task {
            await session.dhtNode.start()
            // Wait for bootstrap nodes to respond before querying
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard session.isRunning else { return }
            await session.dhtNode.getPeers(infoHash: session.infoHash)
        }

        startStatsTimer()
    }

    // MARK: - Pause
    public func pause(id: UUID) async {
        guard let session = sessions[id] else { return }
        session.isRunning = false
        for (_, conn) in session.peers { await conn.disconnect() }
        session.peers.removeAll()
        await persistPieceState(session: session)
    }

    // MARK: - Remove
    public func remove(id: UUID, deleteFiles: Bool) async {
        guard let session = sessions[id] else { return }
        session.isRunning = false
        for (_, conn) in session.peers { await conn.disconnect() }
        session.peers.removeAll()
        await persistPieceState(session: session)
        sessions.removeValue(forKey: id)

        if deleteFiles {
            try? FileManager.default.removeItem(at: session.downloadPath)
        }
    }

    // MARK: - Connect to Peers
    private func connectToPeers(_ peers: [TorrentPeer], session: TorrentSession) async {
        let needed = BTProtocol.maxPeers - session.peers.count
        guard needed > 0 else { return }

        for peer in peers.prefix(needed) {
            let key = peer.address
            guard session.peers[key] == nil else { continue }

            let conn = PeerConnection(
                ip: peer.ip,
                port: peer.port,
                infoHash: session.infoHash,
                localPeerID: localPeerID
            )
            let sessionID = session.torrentID
            let pm = session.pieceManager

            await conn.setOnPieceReceived { [weak self] index, begin, data in
                guard let self else { return }
                Task { await self.handleBlock(sessionID: sessionID, pieceIndex: index, begin: begin, data: data, pm: pm) }
            }
            await conn.setOnDisconnected { [weak self] in
                guard let self else { return }
                Task { await self.removePeer(key: key, sessionID: sessionID) }
            }

            session.peers[key] = conn

            Task {
                do {
                    try await conn.connect()
                    await conn.sendInterested()
                    await self.requestNextPiece(from: conn, pm: pm)
                } catch {
                    await self.removePeer(key: key, sessionID: sessionID)
                }
            }
        }
    }

    private func removePeer(key: String, sessionID: UUID) {
        sessions[sessionID]?.peers.removeValue(forKey: key)
    }

    // MARK: - Block Handling
    private func handleBlock(sessionID: UUID, pieceIndex: Int, begin: Int, data: Data, pm: PieceManager) async {
        guard let session = sessions[sessionID], session.isRunning else { return }

        session.totalDownloaded += Int64(data.count)
        await writeBlock(session: session, pieceIndex: pieceIndex, begin: begin, data: data)

        let pieceSize = await pm.sizeOf(piece: pieceIndex)
        guard let assembled = await readPiece(session: session, index: pieceIndex, size: pieceSize) else { return }

        if await pm.verify(index: pieceIndex, data: assembled) {
            await persistPieceState(session: session)
            let progress = await pm.progress
            if progress >= 1.0 {
                await notifyComplete(id: sessionID)
            } else {
                await notifyUpdate(id: sessionID)
            }
            // Request next piece from all connected peers
            for (_, conn) in session.peers {
                await requestNextPiece(from: conn, pm: pm)
            }
        } else {
            await pm.markFailed(pieceIndex)
        }
    }

    private func requestNextPiece(from conn: PeerConnection, pm: PieceManager) async {
        let available = await conn.availablePieces
        guard let next = await pm.nextPieceToDownload(availableFromPeer: available) else { return }
        await pm.markDownloading(next)
        let pieceSize = await pm.sizeOf(piece: next)
        var offset = 0
        while offset < pieceSize {
            let blockLen = min(BTProtocol.blockSize, pieceSize - offset)
            await conn.sendRequest(pieceIndex: next, begin: offset, length: blockLen)
            offset += blockLen
        }
    }

    // MARK: - Disk I/O
    private func writeBlock(session: TorrentSession, pieceIndex: Int, begin: Int, data: Data) async {
        let pm = session.pieceManager
        let pieceLen = pm.pieceLength
        let offset = Int64(pieceIndex) * Int64(pieceLen) + Int64(begin)
        let path = session.downloadPath.appendingPathComponent("data.bin")

        if !FileManager.default.fileExists(atPath: path.path) {
            FileManager.default.createFile(atPath: path.path, contents: nil)
        }
        guard let fh = try? FileHandle(forWritingTo: path) else { return }
        fh.seek(toFileOffset: UInt64(offset))
        fh.write(data)
        try? fh.close()
    }

    private func readPiece(session: TorrentSession, index: Int, size: Int) async -> Data? {
        let pm = session.pieceManager
        let pieceLen = pm.pieceLength
        let offset = Int64(index) * Int64(pieceLen)
        let path = session.downloadPath.appendingPathComponent("data.bin")
        guard let fh = try? FileHandle(forReadingFrom: path) else { return nil }
        fh.seek(toFileOffset: UInt64(offset))
        let data = fh.readData(ofLength: size)
        try? fh.close()
        return data.count == size ? data : nil
    }

    // MARK: - Piece State Persistence
    private func persistPieceState(session: TorrentSession) async {
        let stateData = await session.pieceManager.serializeStates()
        let stateURL = session.downloadPath.appendingPathComponent("\(session.infoHashHex).pieces")
        try? stateData.write(to: stateURL)
    }

    // MARK: - Stats Timer
    private func startStatsTimer() {
        guard statsTimerTask == nil else { return }
        statsTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { break }
                for id in await self.sessions.keys {
                    await self.notifyUpdate(id: id)
                }
            }
        }
    }

    private func notifyUpdate(id: UUID) async {
        await delegate?.engineDidUpdateTorrent(id: id)
    }

    private func notifyComplete(id: UUID) async {
        await delegate?.engineDidCompleteTorrent(id: id)
    }

    // MARK: - Public Queries
    public func progress(for id: UUID) async -> Double {
        guard let session = sessions[id] else { return 0 }
        return await session.pieceManager.progress
    }

    public func pieceStates(for id: UUID) async -> [TorrentPiece] {
        guard let session = sessions[id] else { return [] }
        return await session.pieceManager.allPieces()
    }

    public func peerCount(for id: UUID) -> Int {
        sessions[id]?.peers.count ?? 0
    }

    public func speeds(for id: UUID) -> (down: Double, up: Double) {
        // Speeds are updated externally by TorrentService via model
        (0, 0)
    }

    // MARK: - Background save
    public func saveAllStates() async {
        for (_, session) in sessions {
            await persistPieceState(session: session)
        }
    }
}

// PieceManager exposes pieceLength, totalSize, sizeOf(piece:) as public members.
