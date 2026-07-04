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
            // Re-register all torrents with engine
            for torrent in torrents where torrent.status == .downloading {
                await resumeTorrent(torrent)
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
        let parsed = try MagnetParser.parse(magnetLink)
        guard !torrents.contains(where: { $0.infoHash == parsed.infoHash }) else {
            throw TorrentEngineError.alreadyExists
        }

        var torrent = TorrentModel(
            infoHash: parsed.infoHash,
            name: parsed.displayName ?? parsed.infoHash,
            magnetLink: magnetLink,
            status: .metadata,
            savePath: await storage.torrentDirectory(for: parsed.infoHash).path
        )
        torrent.trackers = parsed.trackers.map { TorrentTracker(url: $0) }
        torrents.append(torrent)
        try? await storage.saveTorrents(torrents)

        // Start with no pieces yet — metadata fetch would populate these
        // For now, start engine with empty piece info (metadata mode)
        try await engine.addTorrent(
            id: torrent.id,
            infoHash: parsed.infoHash,
            pieceCount: 0,
            pieceLength: 0,
            totalSize: 0,
            pieceHashes: [],
            savePath: await storage.torrentDirectory(for: parsed.infoHash)
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
            trackers: info.trackers.map { TorrentTracker(url: $0) }
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
        await engine.start(id: torrent.id, trackerURLs: info.trackers)
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
        await resumeTorrent(torrent)
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
            torrents[i].progress = progress
            torrents[i].downloadedSize = Int64(Double(torrents[i].totalSize) * progress)
            if progress >= 1.0 && torrents[i].status == .downloading {
                torrents[i].status = .completed
                torrents[i].completedDate = Date()
            }
        }
    }

    // MARK: - Helpers
    private func resumeTorrent(_ torrent: TorrentModel) async {
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
