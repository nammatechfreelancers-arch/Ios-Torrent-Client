// MARK: - PieceManager.swift
// Manages piece state, verification, and download scheduling.

import Foundation
import CryptoKit

public actor PieceManager {
    private let pieceCount: Int
    public let pieceLength: Int
    public let totalSize: Int64
    private let pieceHashes: [Data]   // 20-byte SHA1 per piece
    private var pieceStates: [PieceState]
    private var downloadingPieces: Set<Int> = []

    public init(pieceCount: Int, pieceLength: Int, totalSize: Int64, pieceHashes: [Data]) {
        self.pieceCount = pieceCount
        self.pieceLength = pieceLength
        self.totalSize = totalSize
        self.pieceHashes = pieceHashes
        self.pieceStates = Array(repeating: .missing, count: pieceCount)
    }

    // MARK: - State
    public var verifiedCount: Int { pieceStates.filter { $0 == .verified }.count }
    public var progress: Double { pieceCount > 0 ? Double(verifiedCount) / Double(pieceCount) : 0 }

    public func state(for index: Int) -> PieceState {
        guard index < pieceStates.count else { return .missing }
        return pieceStates[index]
    }

    public func allPieces() -> [TorrentPiece] {
        pieceStates.enumerated().map { TorrentPiece(id: $0.offset, state: $0.element, size: sizeOf(piece: $0.offset)) }
    }

    // MARK: - Scheduling
    /// Returns the next piece index to request, using rarest-first strategy.
    public func nextPieceToDownload(availableFromPeer: Set<Int>) -> Int? {
        guard pieceCount > 0 else { return nil }
        let candidates = availableFromPeer.filter {
            $0 < pieceCount && pieceStates[$0] == .missing && !downloadingPieces.contains($0)
        }
        return candidates.min()
    }

    public func markDownloading(_ index: Int) {
        guard index < pieceStates.count else { return }
        downloadingPieces.insert(index)
        pieceStates[index] = .downloading
    }

    // MARK: - Verification
    /// Verifies a received piece against its SHA1 hash. Returns true if valid.
    public func verify(index: Int, data: Data) -> Bool {
        guard index < pieceHashes.count else { return false }
        let hash = Insecure.SHA1.hash(data: data)
        let hashData = Data(hash)
        let valid = hashData == pieceHashes[index]
        if valid {
            pieceStates[index] = .verified
            downloadingPieces.remove(index)
        } else {
            // Re-queue failed piece
            pieceStates[index] = .missing
            downloadingPieces.remove(index)
        }
        return valid
    }

    public func markFailed(_ index: Int) {
        guard index < pieceStates.count else { return }
        pieceStates[index] = .missing
        downloadingPieces.remove(index)
    }

    // MARK: - Recheck
    public func resetAll() {
        pieceStates = Array(repeating: .missing, count: pieceCount)
        downloadingPieces.removeAll()
    }

    // MARK: - Helpers
    public func sizeOf(piece index: Int) -> Int {
        guard pieceCount > 0, index < pieceCount else { return 0 }
        if index == pieceCount - 1 {
            let remainder = Int(totalSize) % pieceLength
            return remainder == 0 ? pieceLength : remainder
        }
        return pieceLength
    }

    // MARK: - Serialization (for state persistence)
    public func serializeStates() -> Data {
        Data(pieceStates.map { UInt8($0.rawValue) })
    }

    public func restoreStates(from data: Data) {
        for (i, byte) in data.enumerated() where i < pieceCount {
            pieceStates[i] = PieceState(rawValue: Int(byte)) ?? .missing
        }
    }
}
