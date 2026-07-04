// Color+Theme.swift — Semantic color tokens
import SwiftUI

public extension Color {
    // MARK: - Status Colors
    static let statusDownloading = Color.blue
    static let statusSeeding     = Color.green
    static let statusPaused      = Color.orange
    static let statusError       = Color.red
    static let statusCompleted   = Color.teal
    static let statusQueued      = Color.secondary
    static let statusChecking    = Color.purple
    static let statusMetadata    = Color.indigo

    // MARK: - Background
    static let cardBackground    = Color(.secondarySystemGroupedBackground)
    static let pageBackground    = Color(.systemGroupedBackground)
    static let glassBackground   = Color(.systemBackground).opacity(0.7)

    // MARK: - Status from TorrentStatus
    static func statusColor(for status: TorrentStatus) -> Color {
        switch status {
        case .downloading: return .statusDownloading
        case .seeding:     return .statusSeeding
        case .paused:      return .statusPaused
        case .error:       return .statusError
        case .completed:   return .statusCompleted
        case .queued:      return .statusQueued
        case .checking:    return .statusChecking
        case .metadata:    return .statusMetadata
        case .stopped:     return .secondary
        }
    }
}
