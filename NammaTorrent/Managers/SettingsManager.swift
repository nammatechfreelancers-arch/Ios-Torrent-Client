// SettingsManager.swift — Persists AppSettings via UserDefaults
import Foundation
import Observation

@Observable
@MainActor
public final class SettingsManager {
    public static let shared = SettingsManager()

    public var settings: AppSettings {
        didSet { save() }
    }

    // Convenience accessors
    public var maxActiveDownloads: Int { settings.maxActiveDownloads }
    public var downloadSpeedLimit: Int { settings.maxDownloadSpeed }
    public var uploadSpeedLimit: Int { settings.maxUploadSpeed }
    public var globalSeedingEnabled: Bool { settings.maxActiveSeedsLimit > 0 }

    private let key = "app_settings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = saved
        } else {
            settings = AppSettings()
        }
    }

    private func save() {
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    public func reset() {
        settings = AppSettings()
    }
}
