// FileBrowserView.swift
import SwiftUI

public struct FileBrowserView: View {
    @State private var vm: FileBrowserViewModel
    @State private var shareURL: URL?

    public init() {
        let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Downloads")
        _vm = State(initialValue: FileBrowserViewModel(rootURL: root))
    }

    public var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    SkeletonList()
                } else if vm.items.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Files",
                        subtitle: "Downloaded files will appear here."
                    )
                } else {
                    List {
                        ForEach(vm.items, id: \.self) { url in
                            FileItemRow(url: url, isDirectory: url.isDirectory)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if url.isDirectory {
                                        Task { await vm.navigate(to: url) }
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task { await vm.delete(url) }
                                    } label: { Label("Delete", systemImage: "trash") }

                                    Button {
                                        vm.share(url)
                                        shareURL = url
                                    } label: { Label("Share", systemImage: "square.and.arrow.up") }
                                        .tint(.blue)
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(vm.currentURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(url: url)
            }
            .alert("Error", isPresented: .constant(vm.error != nil), presenting: vm.error) { _ in
                Button("OK") { vm.error = nil }
            } message: { e in Text(e.message) }
        }
        .onFirstAppear { await vm.load() }
    }
}

private struct FileItemRow: View {
    let url: URL
    let isDirectory: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isDirectory ? "folder.fill" : fileIcon)
                .font(.title3)
                .foregroundStyle(isDirectory ? .yellow : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                if !isDirectory {
                    Text(url.fileSizeFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var fileIcon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mp4","mkv","avi","mov": return "film"
        case "mp3","flac","aac","wav": return "music.note"
        case "jpg","jpeg","png","gif": return "photo"
        case "pdf": return "doc.richtext"
        case "zip","rar","7z": return "archivebox"
        default: return "doc"
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
