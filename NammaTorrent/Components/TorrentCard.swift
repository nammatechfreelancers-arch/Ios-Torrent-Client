// TorrentCard.swift
import SwiftUI

public struct TorrentCard: View {
    let torrent: TorrentModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ProgressRing(progress: torrent.progress, size: 40, lineWidth: 4,
                             color: .statusColor(for: torrent.status))
                VStack(alignment: .leading, spacing: 2) {
                    Text(torrent.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    StatusBadge(status: torrent.status)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    SpeedBadge(speed: torrent.downloadSpeed, direction: .down)
                    SpeedBadge(speed: torrent.uploadSpeed, direction: .up)
                }
            }
            ProgressView(value: torrent.progress)
                .tint(.statusColor(for: torrent.status))
            HStack {
                Text(Formatters.fileSize(torrent.downloadedSize) + " / " + Formatters.fileSize(torrent.totalSize))
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                if torrent.eta > 0 {
                    Text(Formatters.eta(torrent.eta))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .cardStyle()
    }
}
