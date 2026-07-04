// SettingsViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class SettingsViewModel {
    private let manager = SettingsManager.shared

    var settings: AppSettings {
        get { manager.settings }
        set { manager.settings = newValue }
    }

    var totalDownloadsSize: String = "Calculating..."

    func loadDiskUsage() async {
        let size = await NativeFileManager.shared.totalDownloadsSize()
        totalDownloadsSize = Formatters.fileSize(size)
    }

    func clearAllData() async {
        let root = await NativeFileManager.shared.downloadsRoot()
        try? await NativeFileManager.shared.delete(at: root)
        _ = await NativeFileManager.shared.downloadsRoot() // recreate
        await loadDiskUsage()
    }

    func reset() { manager.reset() }
}
