// FloatingActionButton.swift
import SwiftUI

public struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    var color: Color = .blue

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}
