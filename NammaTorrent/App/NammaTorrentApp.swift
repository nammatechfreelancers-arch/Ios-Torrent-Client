// NammaTorrentApp.swift
import SwiftUI

@main
struct NammaTorrentApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isReady = false

    var body: some Scene {
        WindowGroup {
            if isReady {
                RootTabView()
                    .preferredColorScheme(colorScheme)
                    .tint(SettingsManager.shared.settings.accentColor.color)
                    .onOpenURL { url in
                        handleIncomingURL(url)
                    }
            } else {
                ProgressView("Loading…")
                    .task { await launch() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                Task { await AppContainer.shared.suspend() }
            case .active:
                AppContainer.shared.processPendingShareExtensionItems()
            default:
                break
            }
        }
    }

    private func launch() async {
        await AppContainer.shared.bootstrap()
        isReady = true
    }

    private func handleIncomingURL(_ url: URL) {
        let urlString = url.absoluteString
        if urlString.lowercased().hasPrefix("magnet:") {
            Task {
                try? await TorrentService.shared.addMagnet(urlString)
            }
        } else if url.pathExtension.lowercased() == "torrent" {
            Task.detached {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url) else { return }
                try? await TorrentService.shared.addTorrentFile(data: data)
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch SettingsManager.shared.settings.theme {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }
}

// MARK: - Root Tab View
struct RootTabView: View {
    @State private var selectedTab = 0
    private let settings = SettingsManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Torrents", systemImage: "arrow.down.circle") }
                .tag(0)

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(1)

            FileBrowserView()
                .tabItem { Label("Files", systemImage: "folder") }
                .tag(2)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag(3)

            if settings.settings.developerModeEnabled {
                DeveloperView()
                    .tabItem { Label("Dev", systemImage: "hammer") }
                    .tag(4)
            }
        }
    }
}
