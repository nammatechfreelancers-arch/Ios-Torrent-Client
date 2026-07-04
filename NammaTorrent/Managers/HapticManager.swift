// HapticManager.swift — Haptic feedback wrapper
import UIKit

public final class HapticManager: @unchecked Sendable {
    public static let shared = HapticManager()
    private init() {}

    private let impact = UIImpactFeedbackGenerator(style: .medium)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    public func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard SettingsManager.shared.settings.hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    public func success() {
        guard SettingsManager.shared.settings.hapticsEnabled else { return }
        notification.notificationOccurred(.success)
    }

    public func error() {
        guard SettingsManager.shared.settings.hapticsEnabled else { return }
        notification.notificationOccurred(.error)
    }

    public func warning() {
        guard SettingsManager.shared.settings.hapticsEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    public func selectionChanged() {
        guard SettingsManager.shared.settings.hapticsEnabled else { return }
        selection.selectionChanged()
    }
}
