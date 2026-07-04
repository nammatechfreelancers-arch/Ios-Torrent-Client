// TorrentLiveActivity.swift
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
public struct TorrentLiveActivity: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: TorrentActivityAttributes.self) { context in
            // Lock screen / banner
            LockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(Formatters.speed(context.state.downloadSpeed), systemImage: "arrow.down")
                        .font(.caption2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label(Formatters.speed(context.state.uploadSpeed), systemImage: "arrow.up")
                        .font(.caption2)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.torrentName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.blue)
                        .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text(Formatters.percent(context.state.progress))
                    .font(.caption2.monospacedDigit())
            } minimal: {
                ProgressView(value: context.state.progress)
                    .progressViewStyle(.circular)
                    .tint(.blue)
            }
        }
    }
}

@available(iOS 16.2, *)
private struct LockScreenView: View {
    let state: TorrentActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            ProgressRing(progress: state.progress, size: 44, lineWidth: 4, color: .blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(state.torrentName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Label(Formatters.speed(state.downloadSpeed), systemImage: "arrow.down")
                    Label(Formatters.speed(state.uploadSpeed), systemImage: "arrow.up")
                    if state.eta > 0 {
                        Label(Formatters.eta(state.eta), systemImage: "clock")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
    }
}

// MARK: - Live Activity Manager
#if !APP_EXTENSION
@available(iOS 16.2, *)
public actor LiveActivityManager {
    public static let shared = LiveActivityManager()
    private var activityIDs: Set<String> = []
    private init() {}

    public func start(for torrent: TorrentModel) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attrs = TorrentActivityAttributes(torrentID: torrent.id.uuidString)
        let state = TorrentActivityAttributes.ContentState(
            torrentName: torrent.name,
            progress: torrent.progress,
            downloadSpeed: torrent.downloadSpeed,
            uploadSpeed: torrent.uploadSpeed,
            eta: torrent.eta,
            peerCount: torrent.peerCount,
            status: torrent.status.rawValue,
            health: torrent.health
        )
        if let activity = try? Activity.request(
            attributes: attrs,
            content: .init(state: state, staleDate: nil)
        ) {
            activityIDs.insert(activity.id)
        }
    }

    public func update(for torrent: TorrentModel) async {
        let state = TorrentActivityAttributes.ContentState(
            torrentName: torrent.name,
            progress: torrent.progress,
            downloadSpeed: torrent.downloadSpeed,
            uploadSpeed: torrent.uploadSpeed,
            eta: torrent.eta,
            peerCount: torrent.peerCount,
            status: torrent.status.rawValue,
            health: torrent.health
        )
        let content = ActivityContent(state: state, staleDate: nil)
        for activity in Activity<TorrentActivityAttributes>.activities where activityIDs.contains(activity.id) {
            await activity.update(content)
        }
    }

    public func end(for torrentID: UUID) async {
        for activity in Activity<TorrentActivityAttributes>.activities where activityIDs.contains(activity.id) {
            activityIDs.remove(activity.id)
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
#endif
