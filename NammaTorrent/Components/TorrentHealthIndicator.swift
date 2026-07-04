// TorrentHealthIndicator.swift
import SwiftUI

public struct TorrentHealthIndicator: View {
    let health: Double  // 0.0 – 1.0

    private var color: Color {
        switch health {
        case 0..<0.3: return .red
        case 0.3..<0.6: return .orange
        default: return .green
        }
    }

    private var label: String {
        switch health {
        case 0..<0.3: return "Poor"
        case 0.3..<0.6: return "Fair"
        default: return "Good"
        }
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Double(i) / 5.0 < health ? color : Color.secondary.opacity(0.3))
                    .frame(width: 4, height: CGFloat(6 + i * 3))
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(color)
        }
    }
}
