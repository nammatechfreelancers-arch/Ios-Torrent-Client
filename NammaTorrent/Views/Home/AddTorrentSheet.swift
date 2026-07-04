// AddTorrentSheet.swift
import SwiftUI
import UniformTypeIdentifiers

public struct AddTorrentSheet: View {
    @Bindable var vm: HomeViewModel
    @State private var magnetText = ""
    @State private var showFilePicker = false
    @State private var isAdding = false
    @Environment(\.dismiss) private var dismiss

    private var magnetTrimmed: String { magnetText.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isMagnetValid: Bool { magnetTrimmed.lowercased().hasPrefix("magnet:?") }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Magnet Link") {
                    TextField("magnet:?xt=urn:btih:...", text: $magnetText, axis: .vertical)
                        .lineLimit(3...6)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    Button {
                        guard isMagnetValid, !isAdding else { return }
                        isAdding = true
                        Task {
                            await vm.addMagnet(magnetTrimmed)
                            isAdding = false
                            if vm.error == nil { dismiss() }
                        }
                    } label: {
                        HStack {
                            Text("Add Magnet")
                            if isAdding { Spacer(); ProgressView() }
                        }
                    }
                    .disabled(!isMagnetValid || isAdding)

                    Button("Paste from Clipboard") {
                        if let str = UIPasteboard.general.string {
                            magnetText = str.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    .foregroundStyle(.secondary)
                }

                Section(".torrent File") {
                    Button("Browse Files…") { showFilePicker = true }
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
        .presentationDragIndicator(.visible)
    }
}
