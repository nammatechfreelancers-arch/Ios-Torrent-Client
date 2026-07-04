// NetworkMonitor.swift — Observes network connectivity
import Foundation
import Network
import Observation

@Observable
@MainActor
public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    public var isConnected = true
    public var isExpensive = false   // cellular
    public var isConstrained = false // Low Data Mode

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.nammatorrrent.netmonitor", qos: .utility)

    private init() { start() }

    private func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected   = path.status == .satisfied
                self?.isExpensive   = path.isExpensive
                self?.isConstrained = path.isConstrained
            }
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
