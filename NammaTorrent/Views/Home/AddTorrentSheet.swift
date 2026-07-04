// AddTorrentSheet.swift
import SwiftUI
import UniformTypeIdentifiers

public struct AddTorrentSheet: View {
    @Bindable var vm: HomeViewModel
    @State private var magnetText = ""
    @State private var showFilePicker = false
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            Form {
                Section("Magnet Link") {
                    TextField("magnet:?xt=urn:btih:...", text: $magnetText, axis: .vertical)
                        .lineLimit(3...6)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("Add Magnet") {
                        Task {
                            await vm.addMagnet(magnetText)
                            dismiss()
                        }
                    }
                    .disabled(magnetText.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section(".torrent File") {
                    Button("Browse Files…") { showFilePicker = true }
                }

                Section {
                    Button("Paste from Clipboard") {
                        if let str = UIPasteboard.general.string {
                            magnetText = str
                        }
                    }
                }
            }
            .navigationTitle("Add Torrent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "torrent") ?? .data, .data]
            ) { result in
                guard case .success(let url) = result else { return }
                Task.detached {
                    let accessed = url.startAccessingSecurityScopedResource()
                    defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                    guard let data = try? Data(contentsOf: url) else { return }
                    await MainActor.run {
                        Task {
                            await vm.addTorrentFile(data)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
