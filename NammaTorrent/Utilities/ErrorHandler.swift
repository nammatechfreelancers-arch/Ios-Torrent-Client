// ErrorHandler.swift — Centralized error handling
import Foundation

public struct AppError: LocalizedError, Identifiable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let isRecoverable: Bool

    public var errorDescription: String? { message }

    public init(title: String, message: String, isRecoverable: Bool = true) {
        self.title = title
        self.message = message
        self.isRecoverable = isRecoverable
    }

    public static func from(_ error: Error) -> AppError {
        switch error {
        case let e as TorrentEngineError:
            return AppError(title: "Torrent Error", message: e.localizedDescription)
        case let e as TorrentParserError:
            return AppError(title: "Parse Error", message: e.localizedDescription, isRecoverable: false)
        case let e as TrackerError:
            return AppError(title: "Tracker Error", message: e.localizedDescription)
        case let e as URLError:
            return AppError(title: "Network Error", message: e.localizedDescription)
        default:
            return AppError(title: "Error", message: error.localizedDescription)
        }
    }
}

@MainActor
public final class ErrorHandler {
    public static let shared = ErrorHandler()
    private init() {}

    public var currentError: AppError?
    public var showError = false

    public func handle(_ error: Error) {
        let appError = AppError.from(error)
        currentError = appError
        showError = true
        AppLogger.error(appError.message)
    }

    public func dismiss() {
        currentError = nil
        showError = false
    }
}
