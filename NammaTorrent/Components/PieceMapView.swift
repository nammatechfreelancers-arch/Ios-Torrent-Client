// PieceMapView.swift
import SwiftUI

public struct PieceMapView: View {
    let pieces: [TorrentPiece]
    var columns: Int = 40

    public var body: some View {
        let rows = max(1, (pieces.count + columns - 1) / columns)
        Canvas { ctx, size in
            let cellW = size.width / CGFloat(columns)
            let cellH = size.height / CGFloat(rows)
            for (i, piece) in pieces.enumerated() {
                let col = i % columns
                let row = i / columns
                let rect = CGRect(x: CGFloat(col) * cellW + 0.5,
                                  y: CGFloat(row) * cellH + 0.5,
                                  width: cellW - 1,
                                  height: cellH - 1)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1),
                         with: .color(pieceColor(piece.state)))
            }
        }
        .frame(height: CGFloat(rows) * 10)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func pieceColor(_ state: PieceState) -> Color {
        switch state {
        case .verified:    return .blue
        case .downloading: return .orange
        case .missing:     return Color(.systemFill)
        }
    }
}
