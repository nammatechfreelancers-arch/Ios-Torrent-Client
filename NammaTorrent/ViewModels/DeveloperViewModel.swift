// DeveloperViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class DeveloperViewModel {
    var logLines: [String] = []
    var engineStats: String = ""
    var showClearConfirm = false

    private let engine = TorrentEngine.shared
    private var refreshTask: Task<Void, Never>?

    func onAppear() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func onDisappear() { refreshTask?.cancel() }

    private func refresh() async {
        let service = TorrentService.shared
        let count = service.torrents.count
        let active = service.torrents.filter { $0.isActive }.count
        engineStats = "Torrents: \(count) | Active: \(active)"
    }

    func clearLogs() { logLines.removeAll() }

    func addLog(_ line: String) {
        logLines.append("[\(Date().formatted(date: .omitted, time: .standard))] \(line)")
        if logLines.count > AppConstants.maxLogLines { logLines.removeFirst() }
    }
}
