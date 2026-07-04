// TorrentIntents.swift
import AppIntents
import Foundation

// MARK: - Pause All Intent
struct PauseAllTorrentsIntent: AppIntent {
    static let title: LocalizedStringResource = "Pause All Torrents"
    static let description = IntentDescription("Pauses all active downloads.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let service = TorrentService.shared
        let active = service.torrents.filter { $0.isActive }
        for t in active { await service.pause(id: t.id) }
        return .result(dialog: "Paused \(active.count) torrent(s).")
    }
}

// MARK: - Resume All Intent
struct ResumeAllTorrentsIntent: AppIntent {
    static let title: LocalizedStringResource = "Resume All Torrents"
    static let description = IntentDescription("Resumes all paused downloads.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let service = TorrentService.shared
        let paused = service.torrents.filter { $0.status == .paused }
        for t in paused { await service.resume(id: t.id) }
        return .result(dialog: "Resumed \(paused.count) torrent(s).")
    }
}

// MARK: - Add Magnet Intent
struct AddMagnetIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Magnet Link"
    static let description = IntentDescription("Adds a torrent from a magnet link.")

    @Parameter(title: "Magnet Link")
    var magnetLink: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await TorrentService.shared.addMagnet(magnetLink)
        return .result(dialog: "Torrent added successfully.")
    }
}

// MARK: - App Shortcuts
struct NammaTorrentShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PauseAllTorrentsIntent(),
            phrases: ["Pause all downloads in \(.applicationName)"],
            shortTitle: "Pause All",
            systemImageName: "pause.circle"
        )
        AppShortcut(
            intent: ResumeAllTorrentsIntent(),
            phrases: ["Resume downloads in \(.applicationName)"],
            shortTitle: "Resume All",
            systemImageName: "play.circle"
        )
    }
}
