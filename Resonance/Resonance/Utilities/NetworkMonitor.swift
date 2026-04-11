//  NetworkMonitor.swift
//  Resonance

import Network
import Observation

// MARK: - NetworkMonitor

/// Observes network connectivity using `NWPathMonitor` and exposes
/// the current status as an `@Observable` property for SwiftUI views.
@Observable
final class NetworkMonitor {

    // MARK: - Properties

    /// `true` when the device has a satisfactory network path.
    private(set) var isConnected = true

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.resonance.networkMonitor")

    // MARK: - Init

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }

    deinit {
        monitor.cancel()
    }
}
