// MARK: - AppSettings.swift
import Foundation
import SwiftUI

public enum AppTheme: String, Codable, CaseIterable, Sendable {
    case system = "System"
    case light  = "Light"
    case dark   = "Dark"
}

public enum AccentColor: String, Codable, CaseIterable, Sendable {
    case blue   = "Blue"
    case teal   = "Teal"
    case indigo = "Indigo"
    case orange = "Orange"
    case pink   = "Pink"
    case green  = "Green"

    public var color: Color {
        switch self {
        case .blue:   return .blue
        case .teal:   return .teal
        case .indigo: return .indigo
        case .orange: return .orange
        case .pink:   return .pink
        case .green:  return .green
        }
    }
}

public struct AppSettings: Codable, Sendable {
    // Appearance
    public var theme: AppTheme = .system
    public var accentColor: AccentColor = .blue
    public var showThumbnails: Bool = true

    // Network
    public var wifiOnly: Bool = false
    public var allowCellular: Bool = true
    public var maxDownloadSpeed: Int = 0       // 0 = unlimited (KB/s)
    public var maxUploadSpeed: Int = 0         // 0 = unlimited (KB/s)
    public var maxConnections: Int = 200
    public var maxActiveDownloads: Int = 3
    public var maxActiveSeedsLimit: Int = 5
    public var dhtEnabled: Bool = true
    public var pexEnabled: Bool = true
    public var lsdEnabled: Bool = true
    public var encryptionMode: Int = 1         // 0=disabled,1=enabled,2=forced

    // Storage
    public var downloadPath: String = ""       // set at runtime to Documents/Downloads
    public var preAllocateStorage: Bool = false

    // Notifications
    public var notifyOnComplete: Bool = true
    public var notifyOnError: Bool = true
    public var notifyOnStart: Bool = false

    // Haptics
    public var hapticsEnabled: Bool = true

    // Developer
    public var developerModeEnabled: Bool = false
    public var verboseLogging: Bool = false

    public init() {}
}
