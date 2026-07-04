// TorrentRowView.swift
import SwiftUI

public struct TorrentRowView: View {
    let torrent: TorrentModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                ProgressRing(progress: torrent.progress, size: 52, lineWidth: 5,
                             color: .statusColor(for: torrent.status))

                VStack(alignment: .leading, spacing: 4) {
                    Text(torrent.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StatusBadge(status: torrent.status)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    SpeedBadge(speed: torrent.downloadSpeed, direction: .down)
                    SpeedBadge(speed: torrent.uploadSpeed, direction: .up)
                }
                .fixedSize()
            }

            ProgressView(value: max(0, min(1, torrent.progress)))
                .tint(.statusColor(for: torrent.status))
                .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Text(Formatters.fileSize(torrent.downloadedSize) + " / " + Formatters.fileSize(torrent.totalSize))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("\(torrent.seedCount)", systemImage: "arrow.up.circle")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Label("\(torrent.peerCount)", systemImage: "person.2")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if torrent.eta > 0 {
                    Text(Formatters.eta(torrent.eta))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
