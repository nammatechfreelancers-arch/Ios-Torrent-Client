// HomeViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class HomeViewModel {
    var searchText = ""
    var selectedFilter: TorrentStatus? = nil
    var sortOrder: SortOrder = .dateAdded
    var showAddSheet = false
    var showFilePicker = false
    var isLoading = false
    var error: AppError?

    private let service = TorrentService.shared

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case name      = "Name"
        case progress  = "Progress"
        case size      = "Size"
        case status    = "Status"
    }

    var filteredTorrents: [TorrentModel] {
        var list = service.torrents
        if let filter = selectedFilter { list = list.filter { $0.status == filter } }
        if !searchText.isEmpty { list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) } }
        switch sortOrder {
        case .dateAdded: list.sort { $0.addedDate > $1.addedDate }
        case .name:      list.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .progress:  list.sort { $0.progress > $1.progress }
        case .size:      list.sort { $0.totalSize > $1.totalSize }
        case .status:    list.sort { $0.status.rawValue < $1.status.rawValue }
        }
        return list
    }

    var totalDownloadSpeed: Double { service.torrents.reduce(0) { $0 + $1.downloadSpeed } }
    var totalUploadSpeed: Double   { service.torrents.reduce(0) { $0 + $1.uploadSpeed } }

    func addMagnet(_ link: String) async {
        do {
            try await service.addMagnet(link)
            HapticManager.shared.success()
        } catch {
            self.error = AppError.from(error)
            HapticManager.shared.error()
        }
    }

    func addTorrentFile(_ data: Data) async {
        do {
            try await service.addTorrentFile(data: data)
            HapticManager.shared.success()
        } catch {
            self.error = AppError.from(error)
            HapticManager.shared.error()
        }
    }

    func pause(id: UUID) async { await service.pause(id: id) }
    func resume(id: UUID) async { await service.resume(id: id) }
    func remove(id: UUID, deleteFiles: Bool) async { await service.remove(id: id, deleteFiles: deleteFiles) }
}
