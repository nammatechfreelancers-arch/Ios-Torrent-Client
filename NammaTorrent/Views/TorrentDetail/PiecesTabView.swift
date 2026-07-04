// PiecesTabView.swift
import SwiftUI

public struct PiecesTabView: View {
    let pieces: [TorrentPiece]

    private var verified: Int  { pieces.filter { $0.state == .verified }.count }
    private var downloading: Int { pieces.filter { $0.state == .downloading }.count }
    private var missing: Int   { pieces.filter { $0.state == .missing }.count }

    public var body: some View {
        VStack(spacing: 16) {
            // Piece map
            VStack(alignment: .leading, spacing: 8) {
                Text("Piece Map")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                PieceMapView(pieces: pieces)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
            .cardStyle()
            .padding(.horizontal)

            // Stats
            HStack(spacing: 12) {
                PieceStatCell(label: "Done", count: verified, color: .blue)
                PieceStatCell(label: "Active", count: downloading, color: .orange)
                PieceStatCell(label: "Pending", count: missing, color: Color(.systemFill))
            }
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: .blue,   label: "Verified")
                LegendDot(color: .orange, label: "Downloading")
                LegendDot(color: Color(.systemFill), label: "Missing")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
        }
    }
}

private struct PieceStatCell: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .cardStyle()
    }
}

private struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 8)
            Text(label)
        }
    }
}
