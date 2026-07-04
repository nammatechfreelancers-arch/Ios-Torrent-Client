// ShareViewController.swift — Share Extension entry point
import UIKit
import Social
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        handleIncomingItems()
    }

    private func handleIncomingItems() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            done(); return
        }

        for item in items {
            for provider in item.attachments ?? [] {
                // .torrent file
                if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.data.identifier) { [weak self] data, _ in
                        if let url = data as? URL, url.pathExtension.lowercased() == "torrent",
                           let torrentData = try? Data(contentsOf: url) {
                            self?.saveTorrentFile(torrentData)
                        }
                        self?.done()
                    }
                    return
                }
                // Magnet link via URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] data, _ in
                        if let url = data as? URL, url.scheme == "magnet" {
                            self?.saveMagnetLink(url.absoluteString)
                        }
                        self?.done()
                    }
                    return
                }
                // Plain text magnet
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] data, _ in
                        if let text = data as? String, text.hasPrefix("magnet:?") {
                            self?.saveMagnetLink(text)
                        }
                        self?.done()
                    }
                    return
                }
            }
        }
        done()
    }

    // MARK: - Persist to shared UserDefaults (App Group)
    private func saveTorrentFile(_ data: Data) {
        let defaults = UserDefaults(suiteName: "group.com.nammatorrrent")
        var pending = defaults?.array(forKey: "pendingTorrentData") as? [Data] ?? []
        pending.append(data)
        defaults?.set(pending, forKey: "pendingTorrentData")
    }

    private func saveMagnetLink(_ link: String) {
        let defaults = UserDefaults(suiteName: "group.com.nammatorrrent")
        var pending = defaults?.stringArray(forKey: "pendingMagnets") ?? []
        pending.append(link)
        defaults?.set(pending, forKey: "pendingMagnets")
    }

    private func done() {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
