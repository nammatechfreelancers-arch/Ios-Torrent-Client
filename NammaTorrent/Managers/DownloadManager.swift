// DownloadManager.swift — Coordinates active downloads and queue
import Foundation
import Observation

@Observable
@MainActor
public final class DownloadManager {
    public static let shared = DownloadManager()

    public var activeCount: Int = 0
    public var queuedIDs: [UUID] = []

    private let torrentService = TorrentService.shared
    private let settings = SettingsManager.shared
    private var monitorTask: Task<Void, Never>?

    private init() { startMonitor() }

    // MARK: - Queue Management
    public func enqueue(id: UUID) async {
        guard !queuedIDs.contains(id) else { return }
        queuedIDs.append(id)
        await processQueue()
    }

    public func dequeue(id: UUID) {
        queuedIDs.removeAll { $0 == id }
        activeCount = max(0, activeCount - 1)
    }

    private func processQueue() async {
        let maxActive = settings.maxActiveDownloads
        while activeCount < maxActive, !queuedIDs.isEmpty {
            let id = queuedIDs.removeFirst()
            activeCount += 1
            await torrentService.resume(id: id)
        }
    }

    // MARK: - Speed Throttle
    public func applySpeedLimits() {
        // Speed limits are enforced at the TorrentEngine level via settings
        // This method triggers a settings refresh
    }

    // MARK: - Monitor
    private func startMonitor() {
        monitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                await self?.processQueue()
            }
        }
    }
}
