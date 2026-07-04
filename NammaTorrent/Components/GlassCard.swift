// GlassCard.swift
import SwiftUI

public struct GlassCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(AppConstants.cardPadding)
            .glassStyle()
    }
}
