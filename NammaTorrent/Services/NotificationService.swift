// NotificationService.swift — Local notifications for download events
import Foundation
import UserNotifications

public actor NotificationService {
    public static let shared = NotificationService()
    private init() {}

    public func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    public func notifyCompleted(torrentName: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(torrentName) has finished downloading."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "complete-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    public func notifyError(torrentName: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "Download Error"
        content.body = "\(torrentName): \(message)"
        content.sound = .defaultCritical
        let request = UNNotificationRequest(
            identifier: "error-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    public func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
