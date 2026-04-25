//  UserService.swift
//  Resonance

import Foundation
import OSLog
@preconcurrency import FirebaseFirestore

// MARK: - UserService

actor UserService: UserServiceProtocol {

    // MARK: - Properties

    /// Firestore instance — resolved lazily to ensure Firebase is configured first.
    private var db: Firestore {
        Firestore.firestore()
    }
    private let usersCollection = "users"
    private nonisolated let logger = Logger(subsystem: "com.resonance", category: "user")

    // MARK: - Fetch User

    /// Fetches a user document from Firestore by ID.
    /// - Parameter userId: The user's document ID.
    /// - Returns: The decoded `ResonanceUser`, or `nil` if not found.
    func fetchUser(userId: String) async throws -> ResonanceUser? {
        guard !userId.isEmpty else {
            logger.error("fetchUser called with empty userId")
            return nil
        }
        let snapshot = try await db.collection(usersCollection).document(userId).getDocument()
        guard snapshot.exists, let dict = snapshot.data() else { return nil }
        var mutableDict = dict
        mutableDict["id"] = snapshot.documentID
        return try decodeFromDict(ResonanceUser.self, from: mutableDict)
    }

    // MARK: - Update Profile

    /// Updates the user's profile fields in Firestore.
    /// - Parameter user: The `ResonanceUser` with updated fields.
    func updateProfile(_ user: ResonanceUser) async throws {
        guard let userId = user.id else { return }
        var updated = user
        updated.updatedAt = Date()
        let dict = try encodeToDict(updated)
        try await db.collection(usersCollection).document(userId).setData(dict, merge: true)
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

    /// Updates the user's photo URL.
    func updatePhotoURL(userId: String, photoURL: String) async throws {
        try await db.collection(usersCollection).document(userId).updateData([
            "photoURL": photoURL,
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
        let encoded = try artists.map { artist -> [String: Any] in
            try encodeToDict(artist)
        }
        try await db.collection(usersCollection).document(userId).updateData([
            "topArtists": encoded,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's pronouns.
    func updatePronouns(userId: String, pronouns: String?) async throws {
        let value: Any = pronouns ?? FieldValue.delete()
        try await db.collection(usersCollection).document(userId).updateData([
            "pronouns": value,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's mood / status message.
    func updateMood(userId: String, mood: String?) async throws {
        let value: Any = mood ?? FieldValue.delete()
        try await db.collection(usersCollection).document(userId).updateData([
            "mood": value,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Updates the user's favorite song.
    func updateFavoriteSong(userId: String, song: FavoriteSong?) async throws {
        if let song {
            let dict = try encodeToDict(song)
            try await db.collection(usersCollection).document(userId).updateData([
                "favoriteSong": dict,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await db.collection(usersCollection).document(userId).updateData([
                "favoriteSong": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    /// Updates the user's social links.
    func updateSocialLinks(userId: String, links: SocialLinks?) async throws {
        if let links {
            let dict = try encodeToDict(links)
            try await db.collection(usersCollection).document(userId).updateData([
                "socialLinks": dict,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await db.collection(usersCollection).document(userId).updateData([
                "socialLinks": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - Currently Listening

    /// Updates the user's currently listening status.
    func updateCurrentlyListening(userId: String, listening: CurrentlyListening?) async throws {
        if let listening {
            let dict = try encodeToDict(listening)
            try await db.collection(usersCollection).document(userId).updateData([
                "currentlyListening": dict,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        } else {
            try await db.collection(usersCollection).document(userId).updateData([
                "currentlyListening": FieldValue.delete(),
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
    }

    // MARK: - Taste Profile

    /// Saves or updates the user's taste profile (genres, artists, library data).
    func saveTasteProfile(userId: String, profile: TasteProfile) async throws {
        let dict = try encodeToDict(profile)
        try await db.collection(usersCollection).document(userId).updateData([
            "tasteProfile": dict,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Fetches just the taste profile for a user without loading the full document.
    func fetchTasteProfile(userId: String) async throws -> TasteProfile? {
        guard !userId.isEmpty else { return nil }
        let snapshot = try await db.collection(usersCollection).document(userId).getDocument()
        guard let data = snapshot.data(),
              let profileData = data["tasteProfile"] else { return nil }
        // Re-encode to JSON and decode to TasteProfile
        let json = try JSONSerialization.data(withJSONObject: profileData)
        return try JSONDecoder().decode(TasteProfile.self, from: json)
    }

    // MARK: - Device Token

    /// Stores the FCM registration token in the user's private subcollection.
    func updateDeviceToken(userId: String, token: String) async throws {
        try await db.collection(usersCollection).document(userId)
            .collection("private").document("tokens")
            .setData([
                "deviceToken": token,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
    }

    // MARK: - Listening History

    /// Saves a listening session to the user's history subcollection.
    func saveListeningSession(userId: String, session: ListeningSession) async throws {
        let dict = try encodeToDict(session)
        try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .addDocument(data: dict)
    }

    /// Fetches the user's listening history, ordered by most recent.
    /// - Parameters:
    ///   - userId: The user's ID.
    ///   - limit: Maximum number of sessions to return.
    /// - Returns: An array of `ListeningSession`.
    func fetchListeningHistory(userId: String, limit: Int = 50) async throws -> [ListeningSession] {
        guard !userId.isEmpty else {
            logger.error("fetchListeningHistory called with empty userId")
            return []
        }
        let snapshot = try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .order(by: "listenedAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(ListeningSession.self, from: dict)
        }
    }

    // MARK: - User Listener

    /// Returns an `AsyncStream` that emits user document changes in real time.
    nonisolated func userChanges(userId: String) -> AsyncStream<ResonanceUser?> {
        guard !userId.isEmpty else {
            logger.error("userChanges called with empty userId")
            return AsyncStream { $0.finish() }
        }
        let logger = self.logger
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let listener = db.collection(usersCollection).document(userId)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        logger.error("Error listening to user changes: \(error.localizedDescription)")
                        return
                    }
                    guard let snapshot, snapshot.exists, let dict = snapshot.data() else {
                        continuation.yield(nil)
                        return
                    }
                    var mutableDict = dict
                    mutableDict["id"] = snapshot.documentID
                    let user = decodeFromDictOptional(ResonanceUser.self, from: mutableDict)
                    continuation.yield(user)
                }
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }

    // MARK: - Delete Account

    /// Deletes all user data from Firestore: user document, listening history, and imported playlists.
    func deleteAllUserData(userId: String) async throws {
        guard !userId.isEmpty else {
            logger.error("deleteAllUserData called with empty userId")
            return
        }

        // Delete listening history subcollection
        let sessions = try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .getDocuments()
        for doc in sessions.documents {
            try await doc.reference.delete()
        }
        // Delete the listeningHistory parent document
        try await db.collection("listeningHistory").document(userId).delete()

        // Delete imported playlists subcollection
        let playlists = try await db.collection(usersCollection)
            .document(userId)
            .collection("importedPlaylists")
            .getDocuments()
        for doc in playlists.documents {
            try await doc.reference.delete()
        }

        // Delete the user document itself
        try await db.collection(usersCollection).document(userId).delete()

        logger.info("Deleted all data for user \(userId)")
    }

    /// Deletes only the user document from Firestore.
    /// The `onUserDeleted` Cloud Function handles cascade deletion of
    /// matches, messages, friendRequests, listeningHistory, reports, etc.
    func deleteUserDocument(userId: String) async throws {
        guard !userId.isEmpty else {
            logger.error("deleteUserDocument called with empty userId")
            return
        }
        try await db.collection(usersCollection).document(userId).delete()
        logger.info("Deleted user document for \(userId)")
    }

    // MARK: - Private Data

    /// Fetches the user's private data from `users/{userId}/private/profile`.
    func fetchPrivateData(userId: String) async throws -> PrivateUserData? {
        guard !userId.isEmpty else { return nil }
        let doc = try await db.collection(usersCollection)
            .document(userId)
            .collection("private")
            .document("profile")
            .getDocument()
        guard doc.exists, let dict = doc.data() else { return nil }
        return decodeFromDictOptional(PrivateUserData.self, from: dict)
    }

    // MARK: - Imported Playlists

    /// Saves an imported playlist to the user's `importedPlaylists` subcollection.
    func saveImportedPlaylist(userId: String, playlist: ImportedPlaylist) async throws {
        guard !userId.isEmpty else {
            logger.error("saveImportedPlaylist called with empty userId")
            return
        }
        let dict = try encodeToDict(playlist)
        try await db.collection(usersCollection)
            .document(userId)
            .collection("importedPlaylists")
            .document(playlist.id)
            .setData(dict)
    }

    /// Fetches all imported playlists for a user, ordered by import date.
    func fetchImportedPlaylists(userId: String) async throws -> [ImportedPlaylist] {
        guard !userId.isEmpty else {
            logger.error("fetchImportedPlaylists called with empty userId")
            return []
        }
        let snapshot = try await db.collection(usersCollection)
            .document(userId)
            .collection("importedPlaylists")
            .order(by: "importedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(ImportedPlaylist.self, from: dict)
        }
    }

    /// Deletes an imported playlist from the user's subcollection.
    func deleteImportedPlaylist(userId: String, playlistId: String) async throws {
        guard !userId.isEmpty else {
            logger.error("deleteImportedPlaylist called with empty userId")
            return
        }
        try await db.collection(usersCollection)
            .document(userId)
            .collection("importedPlaylists")
            .document(playlistId)
            .delete()
    }
}
