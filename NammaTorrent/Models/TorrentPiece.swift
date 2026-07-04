// MARK: - TorrentPiece.swift
import Foundation

public enum PieceState: Int, Codable, Sendable {
    case missing     = 0
    case downloading = 1
    case verified    = 2
}

public struct TorrentPiece: Identifiable, Codable, Sendable, Hashable {
    public let id: Int          // piece index
    public var state: PieceState
    public var size: Int        // bytes

    public init(id: Int, state: PieceState = .missing, size: Int = 0) {
        self.id = id
        self.state = state
        self.size = size
    }
}
