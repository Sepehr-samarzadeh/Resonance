//  NotificationServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - NotificationServiceProtocol

/// Protocol defining the interface for push notification services.
/// Used by `AuthViewModel` for testability via dependency injection.
protocol NotificationServiceProtocol: Sendable {

    /// Stores the APNs device token for the given user in Firestore.
    func registerDeviceToken(_ token: String, forUserId userId: String) async throws

    /// Removes the device token when the user signs out.
    func removeDeviceToken(forUserId userId: String) async throws
}
