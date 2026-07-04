// Formatters.swift — Reusable formatters for speed, size, ETA, ratio
import Foundation

public enum Formatters {
    // MARK: - File Size
    public static func fileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Speed
    public static func speed(_ bytesPerSec: Double) -> String {
        "\(fileSize(Int64(bytesPerSec)))/s"
    }

    // MARK: - ETA
    public static func eta(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "∞" }
        if seconds < 60 { return "\(Int(seconds))s" }
        if seconds < 3600 { return "\(Int(seconds / 60))m" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h \(Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60))m" }
        return "\(Int(seconds / 86400))d"
    }

    // MARK: - Ratio
    public static func ratio(_ value: Double) -> String {
        value >= 100 ? "∞" : String(format: "%.2f", value)
    }

    // MARK: - Progress Percent
    public static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100)
    }

    // MARK: - Peer Count
    public static func peers(connected: Int, total: Int) -> String {
        "\(connected) (\(total))"
    }

    // MARK: - Date
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    public static func relativeDate(_ date: Date) -> String {
        relativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
}
