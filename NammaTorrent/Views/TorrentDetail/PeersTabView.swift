// PeersTabView.swift
import SwiftUI

public struct PeersTabView: View {
    let peers: [TorrentPeer]

    public var body: some View {
        Group {
            if peers.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Peers",
                    subtitle: "Connecting to peers…"
                )
                .frame(height: 160)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(peers) { peer in
                        PeerRowView(peer: peer)
                        if peer.id != peers.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .cardStyle()
            }
        }
        .padding(.horizontal)
    }
}

private struct PeerRowView: View {
    let peer: TorrentPeer

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(peer.downloadSpeed > 0 ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(peer.address)
                    .font(.subheadline.monospacedDigit())
                HStack(spacing: 6) {
                    Text(peer.clientName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(peer.source.rawValue.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if peer.isEncrypted {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                SpeedBadge(speed: peer.downloadSpeed, direction: .down)
                SpeedBadge(speed: peer.uploadSpeed, direction: .up)
            }

            ProgressView(value: peer.progress)
                .frame(width: 44)
                .tint(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
