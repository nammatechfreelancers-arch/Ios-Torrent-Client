// Constants.swift — App-wide constants
import Foundation
import SwiftUI

public enum AppConstants {
    // App
    static let appName = "NammaTorrent"
    static let bundleID = "com.nammatorrrent"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    // UI
    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let animationDuration: TimeInterval = 0.3
    static let minTapTarget: CGFloat = 44

    // Torrent
    static let defaultPort: UInt16 = 6881
    static let maxPeers = 50
    static let blockSize = 16_384
    static let maxPipelineRequests = 10
    static let trackerAnnounceInterval: TimeInterval = 1800
    static let keepAliveInterval: TimeInterval = 120

    // Storage
    static let maxLogLines = 1000
    static let speedHistoryLength = 60  // seconds of speed history for graph

    // Magnet
    static let magnetScheme = "magnet"
    static let torrentFileExtension = "torrent"
}
