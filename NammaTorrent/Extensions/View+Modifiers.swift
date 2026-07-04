// View+Modifiers.swift — Reusable SwiftUI view modifiers
import SwiftUI

// MARK: - Card Style
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
    }
}

// MARK: - Glass Effect
struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cornerRadius))
    }
}

// MARK: - Shimmer (skeleton loading)
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .white.opacity(0.4), .clear]),
                    startPoint: .init(x: phase - 0.3, y: 0),
                    endPoint: .init(x: phase + 0.3, y: 0)
                )
                .blendMode(.plusLighter)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

// MARK: - Extensions
public extension View {
    func cardStyle() -> some View { modifier(CardModifier()) }
    func glassStyle() -> some View { modifier(GlassModifier()) }
    func shimmer() -> some View { modifier(ShimmerModifier()) }

    func onFirstAppear(_ action: @escaping () async -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
}

private struct OnFirstAppearModifier: ViewModifier {
    let action: () async -> Void
    @State private var appeared = false

    func body(content: Content) -> some View {
        content.task {
            guard !appeared else { return }
            appeared = true
            await action()
        }
    }
}
