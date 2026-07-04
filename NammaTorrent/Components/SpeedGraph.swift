// SpeedGraph.swift
import SwiftUI

public struct SpeedGraph: View {
    let samples: [Double]   // bytes/sec, newest last
    var color: Color = .blue
    var height: CGFloat = 60

    public var body: some View {
        GeometryReader { geo in
            let max = samples.max() ?? 1
            let pts = points(in: geo.size, max: max)
            ZStack(alignment: .bottomLeading) {
                // Fill
                Path { p in
                    guard pts.count > 1 else { return }
                    p.move(to: CGPoint(x: pts[0].x, y: geo.size.height))
                    pts.forEach { p.addLine(to: $0) }
                    p.addLine(to: CGPoint(x: pts.last!.x, y: geo.size.height))
                    p.closeSubpath()
                }
                .fill(color.opacity(0.15))

                // Line
                Path { p in
                    guard pts.count > 1 else { return }
                    p.move(to: pts[0])
                    pts.dropFirst().forEach { p.addLine(to: $0) }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }

    private func points(in size: CGSize, max: Double) -> [CGPoint] {
        guard samples.count > 1 else { return [] }
        let step = size.width / CGFloat(samples.count - 1)
        return samples.enumerated().map { i, v in
            CGPoint(x: CGFloat(i) * step,
                    y: size.height - CGFloat(v / max) * size.height)
        }
    }
}
