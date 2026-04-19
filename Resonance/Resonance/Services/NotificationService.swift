//  NotificationService.swift
//  Resonance

import Foundation
@preconcurrency import FirebaseFirestore

// MARK: - NotificationService

@MainActor
final class NotificationService: NotificationServiceProtocol, Sendable {

    // MARK: - Properties

    /// Firestore instance — resolved lazily to ensure Firebase is configured first.
    private var db: Firestore {
        Firestore.firestore()
    }

    // MARK: - Device Token Registration

    /// Stores the FCM registration token in the user's private subcollection.
    /// This keeps the token hidden from other users — only the owner and
    /// Cloud Functions (admin SDK) can access it.
    /// - Parameters:
    ///   - token: The FCM registration token string.
    ///   - userId: The user's Firestore document ID.
    func registerDeviceToken(_ token: String, forUserId userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("private").document("tokens")
            .setData([
                "deviceToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Remove Device Token

    /// Removes the device token when the user signs out.
    func removeDeviceToken(forUserId userId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("private").document("tokens")
            .delete()
    }
}
