// TrackersTabView.swift
import SwiftUI

public struct TrackersTabView: View {
    let trackers: [TorrentTracker]

    public var body: some View {
        Group {
            if trackers.isEmpty {
                EmptyStateView(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "No Trackers",
                    subtitle: "No trackers configured."
                )
                .frame(height: 160)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(trackers) { tracker in
                        TrackerRowView(tracker: tracker)
                        if tracker.id != trackers.last?.id {
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

private struct TrackerRowView: View {
    let tracker: TorrentTracker

    private var statusColor: Color {
        switch tracker.status {
        case .working:    return .green
        case .updating:   return .orange
        case .notWorking: return .red
        case .disabled:   return .secondary
        case .unknown:    return .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(tracker.url)
                    .font(.caption.monospacedDigit())
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Spacer()
                Text(tracker.status.rawValue)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
            }
            HStack(spacing: 16) {
                Label("\(tracker.seeders)", systemImage: "arrow.up.circle")
                Label("\(tracker.leechers)", systemImage: "arrow.down.circle")
                Label("\(tracker.peers)", systemImage: "person.2")
                if let next = tracker.nextAnnounce {
                    Spacer()
                    Text("Next: \(next.timeAgo)")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            if let msg = tracker.message, !msg.isEmpty {
                Text(msg)
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
