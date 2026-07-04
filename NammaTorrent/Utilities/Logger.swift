// Logger.swift — Structured logging via OSLog
import Foundation
import OSLog

public enum LogCategory: String {
    case engine   = "Engine"
    case network  = "Network"
    case storage  = "Storage"
    case ui       = "UI"
    case dht      = "DHT"
    case tracker  = "Tracker"
    case peer     = "Peer"
}

public struct AppLogger {
    private static let subsystem = "com.nammatorrrent"

    public static func log(_ message: String, category: LogCategory = .engine, level: OSLogType = .default) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug:   logger.debug("\(message)")
        case .error:   logger.error("\(message)")
        case .fault:   logger.fault("\(message)")
        default:       logger.info("\(message)")
        }
    }

    public static func debug(_ message: String, category: LogCategory = .engine) {
        log(message, category: category, level: .debug)
    }

    public static func error(_ message: String, category: LogCategory = .engine) {
        log(message, category: category, level: .error)
    }

    public static func info(_ message: String, category: LogCategory = .engine) {
        log(message, category: category, level: .default)
    }
}
