// SpeedBadge.swift
import SwiftUI

public enum SpeedDirection { case up, down }

public struct SpeedBadge: View {
    let speed: Double
    let direction: SpeedDirection

    public var body: some View {
        HStack(spacing: 2) {
            Image(systemName: direction == .down ? "arrow.down" : "arrow.up")
                .font(.caption2)
                .foregroundStyle(direction == .down ? Color.blue : Color.green)
            Text(Formatters.speed(speed))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
