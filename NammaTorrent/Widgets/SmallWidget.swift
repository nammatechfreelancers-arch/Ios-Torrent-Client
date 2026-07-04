// SmallWidget.swift
import WidgetKit
import SwiftUI

struct SmallWidget: Widget {
    let kind = "SmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TorrentWidgetProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("NammaTorrent")
        .description("Active download speed at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetView: View {
    let entry: TorrentWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.blue)
                .font(.title2)
            Spacer()
            Text(Formatters.speed(entry.totalDownloadSpeed))
                .font(.title3.weight(.bold).monospacedDigit())
            Text("\(entry.activeCount) active")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
