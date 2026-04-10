//  MatchService.swift
//  Resonance

import Foundation
@preconcurrency import FirebaseFirestore

// MARK: - MatchService

actor MatchService {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let matchesCollection = "matches"

    // MARK: - Real-Time Matching

    /// Finds users who are currently listening to the same song.
    /// - Parameters:
    ///   - songId: The song ID to match on.
    ///   - currentUserId: The current user's ID (excluded from results).
    /// - Returns: An array of user IDs currently listening to the same song.
    func findUsersListeningToSong(songId: String, currentUserId: String) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .whereField("currentlyListening.songId", isEqualTo: songId)
            .getDocuments()

        return snapshot.documents
            .compactMap { $0.documentID }
            .filter { $0 != currentUserId }
    }

    /// Finds users who are currently listening to the same artist.
    /// - Parameters:
    ///   - artistName: The artist name to match on.
    ///   - currentUserId: The current user's ID (excluded from results).
    /// - Returns: An array of user IDs currently listening to the same artist.
    func findUsersListeningToArtist(artistName: String, currentUserId: String) async throws -> [String] {
        let snapshot = try await db.collection("users")
            .whereField("currentlyListening.artistName", isEqualTo: artistName)
            .getDocuments()

        return snapshot.documents
            .compactMap { $0.documentID }
            .filter { $0 != currentUserId }
    }

    // MARK: - Deduplication

    /// Checks if a match already exists between two users (in either direction).
    /// - Parameters:
    ///   - userId1: First user's ID.
    ///   - userId2: Second user's ID.
    /// - Returns: The existing match, or `nil` if none exists.
    func findExistingMatch(userId1: String, userId2: String) async throws -> Match? {
        // Firestore `arrayContains` only supports a single value, so query for one user
        // and filter for the other in-memory.
        let snapshot = try await db.collection(matchesCollection)
            .whereField("userIds", arrayContains: userId1)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Match? in
            var dict = doc.data()
            dict["id"] = doc.documentID
            guard let match = decodeFromDictOptional(Match.self, from: dict) else { return nil }
            // Check that the other user is also in this match
            return match.userIds.contains(userId2) ? match : nil
        }.first
    }

    // MARK: - Create Match

    /// Creates a new match document in Firestore.
    /// - Parameter match: The `Match` to persist.
    /// - Returns: The document ID of the created match.
    @discardableResult
    func createMatch(_ match: Match) async throws -> String {
        let dict = try encodeToDict(match)
        let docRef = try await db.collection(matchesCollection).addDocument(data: dict)
        return docRef.documentID
    }

    /// Creates a real-time match between two users triggered by a song.
    /// - Parameters:
    ///   - userId1: First user's ID.
    ///   - userId2: Second user's ID.
    ///   - song: The song that triggered the match.
    /// - Returns: The document ID of the created match.
    @discardableResult
    func createRealtimeMatch(userId1: String, userId2: String, song: TriggerSong) async throws -> String {
        let match = Match(
            userIds: [userId1, userId2],
            matchType: .realtime,
            triggerSong: song,
            triggerArtist: nil,
            similarityScore: nil,
            createdAt: Date()
        )
        return try await createMatch(match)
    }

    /// Creates a real-time match between two users triggered by an artist.
    /// - Parameters:
    ///   - userId1: First user's ID.
    ///   - userId2: Second user's ID.
    ///   - artist: The artist that triggered the match.
    /// - Returns: The document ID of the created match.
    @discardableResult
    func createArtistMatch(userId1: String, userId2: String, artist: TriggerArtist) async throws -> String {
        let match = Match(
            userIds: [userId1, userId2],
            matchType: .realtime,
            triggerSong: nil,
            triggerArtist: artist,
            similarityScore: nil,
            createdAt: Date()
        )
        return try await createMatch(match)
    }

    // MARK: - Historical Matching

    /// Calculates a similarity score between two users based on their listening history.
    /// - Parameters:
    ///   - userId1: First user's ID.
    ///   - userId2: Second user's ID.
    /// - Returns: A score between 0.0 and 1.0 indicating listening taste similarity.
    func calculateSimilarity(userId1: String, userId2: String) async throws -> Double {
        let history1 = try await fetchListeningArtists(userId: userId1)
        let history2 = try await fetchListeningArtists(userId: userId2)

        guard !history1.isEmpty, !history2.isEmpty else { return 0.0 }

        let set1 = Set(history1)
        let set2 = Set(history2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }

    /// Creates a historical match between two users if their similarity exceeds the threshold.
    /// - Parameters:
    ///   - userId1: First user's ID.
    ///   - userId2: Second user's ID.
    ///   - threshold: Minimum similarity score to create a match (default 0.3).
    /// - Returns: The match document ID if created, or `nil` if below threshold.
    func createHistoricalMatchIfSimilar(
        userId1: String,
        userId2: String,
        threshold: Double = 0.3
    ) async throws -> String? {
        // Don't create duplicate matches
        let existing = try await findExistingMatch(userId1: userId1, userId2: userId2)
        if existing != nil { return nil }

        let score = try await calculateSimilarity(userId1: userId1, userId2: userId2)
        guard score >= threshold else { return nil }

        let match = Match(
            userIds: [userId1, userId2],
            matchType: .historical,
            triggerSong: nil,
            triggerArtist: nil,
            similarityScore: score,
            createdAt: Date()
        )
        return try await createMatch(match)
    }

    // MARK: - Fetch Matches

    /// Fetches a single match by its document ID.
    /// - Parameter id: The match document ID.
    /// - Returns: The `Match` if found, or `nil`.
    func fetchMatch(id: String) async throws -> Match? {
        let doc = try await db.collection(matchesCollection).document(id).getDocument()
        guard doc.exists, var dict = doc.data() else { return nil }
        dict["id"] = doc.documentID
        return decodeFromDictOptional(Match.self, from: dict)
    }

    /// Fetches all matches for a given user.
    /// - Parameter userId: The user's ID.
    /// - Returns: An array of `Match` documents involving the user.
    func fetchMatches(userId: String) async throws -> [Match] {
        let snapshot = try await db.collection(matchesCollection)
            .whereField("userIds", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(Match.self, from: dict)
        }
    }

    /// Returns an `AsyncStream` that emits match changes for a user in real time.
    nonisolated func matchChanges(userId: String) -> AsyncStream<[Match]> {
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let listener = db.collection(matchesCollection)
                .whereField("userIds", arrayContains: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("MatchService: Error listening to matches — \(error.localizedDescription)")
                        return
                    }
                    let matches = snapshot?.documents.compactMap { doc -> Match? in
                        var dict = doc.data()
                        dict["id"] = doc.documentID
                        return decodeFromDictOptional(Match.self, from: dict)
                    } ?? []
                    continuation.yield(matches)
                }
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }

    // MARK: - Fetch Recent User IDs (for historical matching)

    /// Fetches user IDs who have been active recently (have listening sessions).
    /// - Parameters:
    ///   - excludingUserId: The current user's ID to exclude.
    ///   - limit: Maximum number of user IDs to return.
    /// - Returns: An array of user IDs.
    func fetchRecentUserIds(excluding excludingUserId: String, limit: Int = 20) async throws -> [String] {
        // Get user documents that have a "currentlyListening" field or have been updated recently
        let snapshot = try await db.collection("users")
            .order(by: "updatedAt", descending: true)
            .limit(to: limit + 1) // +1 to account for excluding self
            .getDocuments()

        return snapshot.documents
            .map { $0.documentID }
            .filter { $0 != excludingUserId }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Private Helpers

    private func fetchListeningArtists(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .order(by: "listenedAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            doc.data()["artistName"] as? String
        }
    }
}
