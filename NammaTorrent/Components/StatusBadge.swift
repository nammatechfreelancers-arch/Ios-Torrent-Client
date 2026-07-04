// StatusBadge.swift
import SwiftUI

public struct StatusBadge: View {
    let status: TorrentStatus

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(.statusColor(for: status))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.statusColor(for: status).opacity(0.12))
        .clipShape(Capsule())
    }
}

// Convenience ShapeStyle extension for statusColor
extension ShapeStyle where Self == Color {
    static func statusColor(for status: TorrentStatus) -> Color {
        Color.statusColor(for: status)
    }
}
