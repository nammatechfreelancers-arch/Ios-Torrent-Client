// MediumWidget.swift
import WidgetKit
import SwiftUI

struct MediumWidget: Widget {
    let kind = "MediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TorrentWidgetProvider()) { entry in
            MediumWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("NammaTorrent")
        .description("Top active torrents with progress.")
        .supportedFamilies([.systemMedium])
    }
}

struct MediumWidgetView: View {
    let entry: TorrentWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Speed summary
            VStack(alignment: .leading, spacing: 8) {
                Label(Formatters.speed(entry.totalDownloadSpeed), systemImage: "arrow.down")
                    .font(.subheadline.weight(.semibold))
                Label(Formatters.speed(entry.totalUploadSpeed), systemImage: "arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                Spacer()
                Text("\(entry.activeCount) of \(entry.totalCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            // Top 2 torrents
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.topTorrents.prefix(2)) { t in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.name).font(.caption.weight(.semibold)).lineLimit(1)
                        ProgressView(value: t.progress).tint(.blue)
                        Text(Formatters.percent(t.progress)).font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding()
    }
}
