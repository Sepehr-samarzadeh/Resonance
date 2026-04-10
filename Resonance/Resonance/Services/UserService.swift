//  UserService.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - UserService

actor UserService {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let usersCollection = "users"

    // MARK: - Fetch User

    /// Fetches a user document from Firestore by ID.
    /// - Parameter userId: The user's document ID.
    /// - Returns: The decoded `ResonanceUser`, or `nil` if not found.
    func fetchUser(userId: String) async throws -> ResonanceUser? {
        let snapshot = try await db.collection(usersCollection).document(userId).getDocument()
        return try snapshot.data(as: ResonanceUser.self)
    }

    // MARK: - Update Profile

    /// Updates the user's profile fields in Firestore.
    /// - Parameter user: The `ResonanceUser` with updated fields.
    func updateProfile(_ user: ResonanceUser) async throws {
        guard let userId = user.id else { return }
        var updated = user
        updated.updatedAt = Date()
        try db.collection(usersCollection).document(userId).setData(from: updated, merge: true)
    }

    /// Updates the user's display name.
    func updateDisplayName(userId: String, displayName: String) async throws {
        try await db.collection(usersCollection).document(userId).updateData([
            "displayName": displayName,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's bio.
    func updateBio(userId: String, bio: String) async throws {
        try await db.collection(usersCollection).document(userId).updateData([
            "bio": bio,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's favorite genres.
    func updateFavoriteGenres(userId: String, genres: [String]) async throws {
        try await db.collection(usersCollection).document(userId).updateData([
            "favoriteGenres": genres,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's top artists.
    func updateTopArtists(userId: String, artists: [TopArtist]) async throws {
        let encoded = try artists.map { try Firestore.Encoder().encode($0) }
        try await db.collection(usersCollection).document(userId).updateData([
            "topArtists": encoded,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Currently Listening

    /// Updates the user's currently listening status.
    func updateCurrentlyListening(userId: String, listening: CurrentlyListening?) async throws {
        if let listening {
            let encoded = try Firestore.Encoder().encode(listening)
            try await db.collection(usersCollection).document(userId).updateData([
                "currentlyListening": encoded,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await db.collection(usersCollection).document(userId).updateData([
                "currentlyListening": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - Device Token

    /// Stores the APNs device token for push notifications.
    func updateDeviceToken(userId: String, token: String) async throws {
        try await db.collection(usersCollection).document(userId).updateData([
            "deviceToken": token,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Listening History

    /// Saves a listening session to the user's history subcollection.
    func saveListeningSession(userId: String, session: ListeningSession) async throws {
        try db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .addDocument(from: session)
    }

    /// Fetches the user's listening history, ordered by most recent.
    /// - Parameters:
    ///   - userId: The user's ID.
    ///   - limit: Maximum number of sessions to return.
    /// - Returns: An array of `ListeningSession`.
    func fetchListeningHistory(userId: String, limit: Int = 50) async throws -> [ListeningSession] {
        let snapshot = try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .order(by: "listenedAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ListeningSession.self)
        }
    }

    // MARK: - User Listener

    /// Returns an `AsyncStream` that emits user document changes in real time.
    func userChanges(userId: String) -> AsyncStream<ResonanceUser?> {
        AsyncStream { continuation in
            let listener = db.collection(usersCollection).document(userId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("UserService: Error listening to user changes — \(error.localizedDescription)")
                        return
                    }
                    let user = try? snapshot?.data(as: ResonanceUser.self)
                    continuation.yield(user)
                }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Delete Account

    /// Deletes the user's Firestore document.
    func deleteUser(userId: String) async throws {
        try await db.collection(usersCollection).document(userId).delete()
    }
}
