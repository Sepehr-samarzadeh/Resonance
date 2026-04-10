//  NotificationService.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - NotificationService

@MainActor
final class NotificationService: Sendable {

    // MARK: - Properties

    private let db = Firestore.firestore()

    // MARK: - Device Token Registration

    /// Stores the APNs device token for the given user in Firestore.
    /// - Parameters:
    ///   - token: The device token as a hex string.
    ///   - userId: The user's Firestore document ID.
    func registerDeviceToken(_ token: String, forUserId userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "deviceToken": token,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Converts raw APNs device token data to a hex string.
    /// - Parameter deviceToken: The raw token data from `didRegisterForRemoteNotificationsWithDeviceToken`.
    /// - Returns: A hex-encoded string representation of the token.
    nonisolated func tokenString(from deviceToken: Data) -> String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }

    // MARK: - Remove Device Token

    /// Removes the device token when the user signs out.
    func removeDeviceToken(forUserId userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "deviceToken": FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
}
