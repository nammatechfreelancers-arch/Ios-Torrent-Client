// AppContainer.swift — DI container wiring all singletons
import SwiftUI

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let torrentService  = TorrentService.shared
    let storageService  = StorageService.shared
    let settingsManager = SettingsManager.shared
    let downloadManager = DownloadManager.shared
    let networkMonitor  = NetworkMonitor.shared
    let haptics         = HapticManager.shared

    private init() {}

    // Called once at app launch
    func bootstrap() async {
        await torrentService.load()
        _ = await NotificationService.shared.requestPermission()
        processPendingShareExtensionItems()
    }

    // Drain items queued by the Share Extension
    func processPendingShareExtensionItems() {
        let defaults = UserDefaults(suiteName: "group.com.nammatorrrent")

        // Magnet links
        if let magnets = defaults?.stringArray(forKey: "pendingMagnets") {
            defaults?.removeObject(forKey: "pendingMagnets")
            for link in magnets {
                Task { try? await torrentService.addMagnet(link) }
            }
        }

        // .torrent data blobs
        if let blobs = defaults?.array(forKey: "pendingTorrentData") as? [Data] {
            defaults?.removeObject(forKey: "pendingTorrentData")
            for data in blobs {
                Task { try? await torrentService.addTorrentFile(data: data) }
            }
        }
    }

    // Called when app moves to background
    func suspend() async {
        await torrentService.saveState()
    }
}
