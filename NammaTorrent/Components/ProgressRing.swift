// ProgressRing.swift
import SwiftUI

public struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 5
    var color: Color = .blue

    public var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            Text(Formatters.percent(progress))
                .font(.system(size: size * 0.22, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
    }
}
