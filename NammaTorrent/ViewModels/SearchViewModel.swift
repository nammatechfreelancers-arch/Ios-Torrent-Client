// SearchViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class SearchViewModel {
    var query = ""
    var results: [TorrentModel] = []
    var isSearching = false

    private let service = TorrentService.shared

    func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        results = service.torrents.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.infoHash.localizedCaseInsensitiveContains(query)
        }
    }

    func clear() {
        query = ""
        results = []
    }

    // Paste magnet or hash directly from search
    func handlePaste(_ text: String) async -> Bool {
        if text.isMagnetLink {
            do {
                try await service.addMagnet(text)
                return true
            } catch { return false }
        }
        return false
    }
}
