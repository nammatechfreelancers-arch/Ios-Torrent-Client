// LargeWidget.swift
import WidgetKit
import SwiftUI

// MARK: - Shared Widget Entry
struct TorrentWidgetEntry: TimelineEntry {
    let date: Date
    let topTorrents: [TorrentModel]
    let totalDownloadSpeed: Double
    let totalUploadSpeed: Double
    let activeCount: Int
    let totalCount: Int

    static let placeholder = TorrentWidgetEntry(
        date: Date(),
        topTorrents: [],
        totalDownloadSpeed: 0,
        totalUploadSpeed: 0,
        activeCount: 0,
        totalCount: 0
    )
}

// MARK: - Shared Provider
struct TorrentWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TorrentWidgetEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (TorrentWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TorrentWidgetEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .second, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> TorrentWidgetEntry {
        // Widgets run in extension — read persisted data from shared UserDefaults/App Group
        // For now return placeholder; wire up App Group in Xcode project settings
        .placeholder
    }
}

// MARK: - Large Widget
struct LargeWidget: Widget {
    let kind = "LargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TorrentWidgetProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("NammaTorrent")
        .description("All active torrents with detailed progress.")
        .supportedFamilies([.systemLarge])
    }
}

struct LargeWidgetView: View {
    let entry: TorrentWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "arrow.down.circle.fill").foregroundStyle(.blue)
                Text("NammaTorrent").font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Label(Formatters.speed(entry.totalDownloadSpeed), systemImage: "arrow.down")
                        .font(.caption2)
                    Label(Formatters.speed(entry.totalUploadSpeed), systemImage: "arrow.up")
                        .font(.caption2).foregroundStyle(.green)
                }
            }
            Divider()
            // Torrent list
            if entry.topTorrents.isEmpty {
                Spacer()
                Text("No active downloads")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(entry.topTorrents.prefix(5)) { t in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(t.name).font(.caption.weight(.semibold)).lineLimit(1)
                            Spacer()
                            Text(Formatters.percent(t.progress))
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: t.progress).tint(.statusColor(for: t.status))
                        HStack {
                            Label(Formatters.speed(t.downloadSpeed), systemImage: "arrow.down")
                            Spacer()
                            if t.eta > 0 { Text(Formatters.eta(t.eta)) }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
