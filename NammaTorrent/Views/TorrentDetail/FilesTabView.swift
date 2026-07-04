// FilesTabView.swift
import SwiftUI

public struct FilesTabView: View {
    let files: [TorrentFile]

    public var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(files) { file in
                FileRowView(file: file)
                if file.id != files.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }
}

private struct FileRowView: View {
    let file: TorrentFile

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: file.systemImage)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(Formatters.fileSize(file.size))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(Formatters.percent(file.progress))
                        .font(.caption)
                        .foregroundStyle(file.progress >= 1.0 ? .green : .secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                ProgressView(value: file.progress)
                    .frame(width: 60)
                    .tint(file.progress >= 1.0 ? .green : .blue)
                Text(file.priority == .skip ? "Skipped" : file.priority == .high ? "High" : "Normal")
                    .font(.caption2)
                    .foregroundStyle(file.priority == .skip ? .red : .secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
