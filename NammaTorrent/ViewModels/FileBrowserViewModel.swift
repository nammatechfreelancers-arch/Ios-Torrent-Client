// FileBrowserViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
public final class FileBrowserViewModel {
    var currentURL: URL
    var items: [URL] = []
    var isLoading = false
    var error: AppError?
    var selectedURL: URL?
    var showShareSheet = false

    private let fileManager = NativeFileManager.shared

    init(rootURL: URL) {
        self.currentURL = rootURL
    }

    func load() async {
        isLoading = true
        items = await fileManager.listFiles(at: currentURL)
            .sorted { $0.lastPathComponent.localizedCompare($1.lastPathComponent) == .orderedAscending }
        isLoading = false
    }

    func navigate(to url: URL) async {
        currentURL = url
        await load()
    }

    func delete(_ url: URL) async {
        do {
            try await fileManager.delete(at: url)
            await load()
        } catch {
            self.error = AppError.from(error)
        }
    }

    func share(_ url: URL) {
        selectedURL = url
        showShareSheet = true
    }

    func totalSize() async -> Int64 {
        await fileManager.totalDownloadsSize()
    }
}
