// TorrentRowView.swift
import SwiftUI

public struct TorrentRowView: View {
    let torrent: TorrentModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ProgressRing(progress: torrent.progress, size: 44, lineWidth: 4,
                             color: .statusColor(for: torrent.status))
                VStack(alignment: .leading, spacing: 3) {
                    Text(torrent.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        StatusBadge(status: torrent.status)
                        TorrentHealthIndicator(health: torrent.health)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 3) {
                    SpeedBadge(speed: torrent.downloadSpeed, direction: .down)
                    SpeedBadge(speed: torrent.uploadSpeed, direction: .up)
                }
            }
            ProgressView(value: torrent.progress)
                .tint(.statusColor(for: torrent.status))
            HStack {
                Text(Formatters.fileSize(torrent.downloadedSize) + " / " + Formatters.fileSize(torrent.totalSize))
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 8) {
                    Label("\(torrent.seedCount)", systemImage: "arrow.up.circle")
                    Label("\(torrent.peerCount)", systemImage: "person.2")
                }
                .font(.caption2).foregroundStyle(.secondary)
                if torrent.eta > 0 {
                    Text(Formatters.eta(torrent.eta))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
    }
}
