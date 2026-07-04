// SkeletonView.swift
import SwiftUI

public struct SkeletonRow: View {
    public var body: some View {
        HStack(spacing: 12) {
            Circle().frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).frame(height: 12)
                RoundedRectangle(cornerRadius: 4).frame(width: 120, height: 10)
            }
            Spacer()
        }
        .foregroundStyle(Color(.systemFill))
        .padding(AppConstants.cardPadding)
        .cardStyle()
        .shimmer()
    }
}

public struct SkeletonList: View {
    var count: Int = 4

    public var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { _ in SkeletonRow() }
        }
        .padding(.horizontal)
    }
}
