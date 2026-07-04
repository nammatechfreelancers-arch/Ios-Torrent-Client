// TorrentService.swift — @Observable service bridging TorrentEngine ↔ ViewModels
import Foundation
import Observation

@Observable
@MainActor
public final class TorrentService {
    public static let shared = TorrentService()

    public var torrents: [TorrentModel] = []
    public var isLoading = false
    public var error: Error?

    private let engine = TorrentEngine.shared
    private let storage = StorageService.shared
    private var speedUpdateTask: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle
    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            torrents = try await storage.loadTorrents()
            // Re-register ALL torrents with engine, then resume active ones
            for torrent in torrents {
                await registerWithEngine(torrent)
                if torrent.status == .downloading || torrent.status == .metadata {
                    await startDownload(torrent)
                }
            }
        } catch {
            self.error = error
        }
        startSpeedUpdates()
    }

    public func saveState() async {
        try? await storage.saveTorrents(torrents)
        await engine.saveAllStates()
    }

    // MARK: - Add via Magnet
    public func addMagnet(_ magnetLink: String) async throws {
        let trimmed = magnetLink.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsed = try MagnetParser.parse(trimmed)
        guard !torrents.contains(where: { $0.infoHash == parsed.infoHash }) else {
            throw TorrentEngineError.alreadyExists
        }

        let savePath = await storage.torrentDirectory(for: parsed.infoHash)
        var torrent = TorrentModel(
            infoHash: parsed.infoHash,
            name: parsed.displayName,
            magnetLink: trimmed,
            status: .metadata,
            savePath: savePath.path
        )
        torrent.trackers = parsed.trackers.map { TorrentTracker(url: $0) }
        torrents.append(torrent)
        try? await storage.saveTorrents(torrents)

        try await engine.addTorrent(
            id: torrent.id,
            infoHash: parsed.infoHash,
            pieceCount: 0,
            pieceLength: 0,
            totalSize: 0,
            pieceHashes: [],
            savePath: savePath
        )
        await engine.start(id: torrent.id, trackerURLs: parsed.trackers)
        updateStatus(id: torrent.id, status: .downloading)
    }

    // MARK: - Add via .torrent file
    public func addTorrentFile(data: Data) async throws {
        let info = try TorrentParser.parse(data: data)
        guard !torrents.contains(where: { $0.infoHash == info.infoHash }) else {
            throw TorrentEngineError.alreadyExists
        }

        let savePath = await storage.torrentDirectory(for: info.infoHash)
        try? await storage.saveTorrentFile(data, infoHash: info.infoHash)

        let torrent = TorrentModel(
            infoHash: info.infoHash,
            name: info.name,
            status: .queued,
            totalSize: info.totalSize,
            savePath: savePath.path,
            files: info.files,
            isPrivate: info.isPrivate,
            hasMetadata: true,
            trackers: info.trackers
        )
        torrents.append(torrent)
        try? await storage.saveTorrents(torrents)

        try await engine.addTorrent(
            id: torrent.id,
            infoHash: info.infoHash,
            pieceCount: info.pieceCount,
            pieceLength: info.pieceLength,
            totalSize: info.totalSize,
            pieceHashes: info.pieceHashes,
            savePath: savePath
        )
        await engine.start(id: torrent.id, trackerURLs: info.trackers.map { $0.url })
        updateStatus(id: torrent.id, status: .downloading)
    }

    // MARK: - Controls
    public func pause(id: UUID) async {
        await engine.pause(id: id)
        updateStatus(id: id, status: .paused)
        try? await storage.saveTorrents(torrents)
    }

    public func resume(id: UUID) async {
        guard let torrent = torrents.first(where: { $0.id == id }) else { return }
        // Always re-register before starting — session may be gone after app restart
        await registerWithEngine(torrent)
        await startDownload(torrent)
    }

    public func remove(id: UUID, deleteFiles: Bool) async {
        await engine.remove(id: id, deleteFiles: deleteFiles)
        if deleteFiles, let torrent = torrents.first(where: { $0.id == id }) {
            try? await storage.deleteTorrentData(infoHash: torrent.infoHash)
        }
        torrents.removeAll { $0.id == id }
        try? await storage.saveTorrents(torrents)
    }

    // MARK: - Speed Updates
    private func startSpeedUpdates() {
        speedUpdateTask?.cancel()
        speedUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { break }
                await self.refreshProgress()
            }
        }
    }

    private func refreshProgress() async {
        for i in torrents.indices {
            let id = torrents[i].id
            let progress = await engine.progress(for: id)
            let peerCount = await engine.peerCount(for: id)
            torrents[i].progress = progress
            torrents[i].peerCount = peerCount
            torrents[i].downloadedSize = Int64(Double(torrents[i].totalSize) * progress)
            if progress >= 1.0 && torrents[i].status == .downloading {
                torrents[i].status = .completed
                torrents[i].completedDate = Date()
            }
        }
    }

    // MARK: - Private Helpers

    /// Registers a torrent with the engine, restoring piece info from saved .torrent file if available.
    private func registerWithEngine(_ torrent: TorrentModel) async {
        let savePath = await storage.torrentDirectory(for: torrent.infoHash)

        // Try to load saved .torrent file for full piece info
        if let savedData = try? await storage.loadTorrentFile(infoHash: torrent.infoHash),
           let info = try? TorrentParser.parse(data: savedData) {
            try? await engine.addTorrent(
                id: torrent.id,
                infoHash: torrent.infoHash,
                pieceCount: info.pieceCount,
                pieceLength: info.pieceLength,
                totalSize: info.totalSize,
                pieceHashes: info.pieceHashes,
                savePath: savePath
            )
        } else {
            // Magnet / no metadata yet — register with empty pieces
            try? await engine.addTorrent(
                id: torrent.id,
                infoHash: torrent.infoHash,
                pieceCount: 0,
                pieceLength: 0,
                totalSize: torrent.totalSize,
                pieceHashes: [],
                savePath: savePath
            )
        }
    }

    private func startDownload(_ torrent: TorrentModel) async {
        let trackerURLs = torrent.trackers.map { $0.url }
        await engine.start(id: torrent.id, trackerURLs: trackerURLs)
        updateStatus(id: torrent.id, status: .downloading)
    }

    private func updateStatus(id: UUID, status: TorrentStatus) {
        guard let i = torrents.firstIndex(where: { $0.id == id }) else { return }
        torrents[i].status = status
        torrents[i].lastActiveDate = Date()
    }
}
