// TorrentDetailViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class TorrentDetailViewModel {
    let torrentID: UUID
    var pieces: [TorrentPiece] = []
    var speedHistory: [Double] = Array(repeating: 0, count: AppConstants.speedHistoryLength)
    var selectedTab = 0

    private let service = TorrentService.shared
    private let engine = TorrentEngine.shared
    private var refreshTask: Task<Void, Never>?

    var torrent: TorrentModel? { service.torrents.first { $0.id == torrentID } }

    init(torrentID: UUID) {
        self.torrentID = torrentID
    }

    func onAppear() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func onDisappear() { refreshTask?.cancel() }

    private func refresh() async {
        pieces = await engine.pieceStates(for: torrentID)
        if let speed = torrent?.downloadSpeed {
            speedHistory.append(speed)
            if speedHistory.count > AppConstants.speedHistoryLength { speedHistory.removeFirst() }
        }
    }

    func pause() async { await service.pause(id: torrentID) }
    func resume() async { await service.resume(id: torrentID) }
    func remove(deleteFiles: Bool) async { await service.remove(id: torrentID, deleteFiles: deleteFiles) }
}
