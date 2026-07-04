// TorrentEngineTests.swift
import Testing
@testable import NammaTorrent

@Suite("TorrentEngine")
struct TorrentEngineTests {

    // MARK: - PieceManager
    @Test func pieceManagerInitialProgress() async {
        let pm = PieceManager(pieceCount: 10, pieceLength: 512, totalSize: 5120, pieceHashes: Array(repeating: Data(count: 20), count: 10))
        let progress = await pm.progress
        #expect(progress == 0.0)
    }

    @Test func pieceManagerMarkDownloading() async {
        let pm = PieceManager(pieceCount: 5, pieceLength: 512, totalSize: 2560, pieceHashes: Array(repeating: Data(count: 20), count: 5))
        await pm.markDownloading(0)
        let state = await pm.state(for: 0)
        #expect(state == .downloading)
    }

    @Test func pieceManagerMarkFailed() async {
        let pm = PieceManager(pieceCount: 5, pieceLength: 512, totalSize: 2560, pieceHashes: Array(repeating: Data(count: 20), count: 5))
        await pm.markDownloading(1)
        await pm.markFailed(1)
        let state = await pm.state(for: 1)
        #expect(state == .missing)
    }

    @Test func pieceManagerNextPiece() async {
        let pm = PieceManager(pieceCount: 5, pieceLength: 512, totalSize: 2560, pieceHashes: Array(repeating: Data(count: 20), count: 5))
        let next = await pm.nextPieceToDownload(availableFromPeer: [0, 1, 2])
        #expect(next != nil)
    }

    @Test func pieceManagerSerializeRestore() async {
        let pm = PieceManager(pieceCount: 4, pieceLength: 512, totalSize: 2048, pieceHashes: Array(repeating: Data(count: 20), count: 4))
        await pm.markDownloading(0)
        await pm.markDownloading(2)
        let serialized = await pm.serializeStates()
        #expect(serialized.count == 4)
        await pm.resetAll()
        await pm.restoreStates(from: serialized)
        let state0 = await pm.state(for: 0)
        #expect(state0 == .downloading)
    }

    // MARK: - BitTorrentProtocol
    @Test func peerIDLength() {
        let id = PeerIDGenerator.generate()
        #expect(id.count == 20)
    }

    @Test func peerIDPrefix() {
        let id = PeerIDGenerator.generate()
        let prefix = String(data: id.prefix(8), encoding: .utf8)
        #expect(prefix == "-NT0100-")
    }

    @Test func handshakeBuildLength() {
        let infoHash = Data(count: 20)
        let peerID = PeerIDGenerator.generate()
        let hs = HandshakeBuilder.build(infoHash: infoHash, peerID: peerID)
        #expect(hs.count == BTProtocol.handshakeLength)
    }

    @Test func handshakeValidation() {
        let infoHash = Data((0..<20).map { UInt8($0) })
        let peerID = PeerIDGenerator.generate()
        let hs = HandshakeBuilder.build(infoHash: infoHash, peerID: peerID)
        #expect(HandshakeBuilder.validate(hs, expectedInfoHash: infoHash))
    }

    @Test func infoHashHexRoundtrip() {
        let hex = "dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c"
        let data = InfoHashHelper.fromHex(hex)
        #expect(data != nil)
        #expect(InfoHashHelper.toHex(data!) == hex)
    }

    @Test func bitfieldHasPiece() {
        let bits = Data.bitfield(pieceCount: 8, verifiedPieces: [0, 3, 7])
        #expect(bits.hasPiece(0))
        #expect(bits.hasPiece(3))
        #expect(bits.hasPiece(7))
        #expect(!bits.hasPiece(1))
        #expect(!bits.hasPiece(5))
    }

    // MARK: - TorrentEngine singleton
    @Test func engineAddDuplicateThrows() async throws {
        let engine = TorrentEngine.shared
        let id = UUID()
        let hash = "aabbccddeeff00112233445566778899aabbccdd"
        let savePath = FileManager.default.temporaryDirectory.appendingPathComponent(id.uuidString)
        try FileManager.default.createDirectory(at: savePath, withIntermediateDirectories: true)

        try await engine.addTorrent(id: id, infoHash: hash, pieceCount: 1, pieceLength: 512,
                                    totalSize: 512, pieceHashes: [Data(count: 20)], savePath: savePath)
        await #expect(throws: TorrentEngineError.self) {
            try await engine.addTorrent(id: id, infoHash: hash, pieceCount: 1, pieceLength: 512,
                                        totalSize: 512, pieceHashes: [Data(count: 20)], savePath: savePath)
        }
        await engine.remove(id: id, deleteFiles: true)
    }
}
