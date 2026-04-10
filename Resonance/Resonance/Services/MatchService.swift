//  MatchService.swift
//  Resonance

import Foundation
import FirebaseFirestore

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

    // MARK: - Create Match

    /// Creates a new match document in Firestore.
    /// - Parameter match: The `Match` to persist.
    /// - Returns: The document ID of the created match.
    @discardableResult
    func createMatch(_ match: Match) async throws -> String {
        let docRef = try db.collection(matchesCollection).addDocument(from: match)
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

    /// Fetches all matches for a given user.
    /// - Parameter userId: The user's ID.
    /// - Returns: An array of `Match` documents involving the user.
    func fetchMatches(userId: String) async throws -> [Match] {
        let snapshot = try await db.collection(matchesCollection)
            .whereField("userIds", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Match.self)
        }
    }

    /// Returns an `AsyncStream` that emits match changes for a user in real time.
    func matchChanges(userId: String) -> AsyncStream<[Match]> {
        AsyncStream { continuation in
            let listener = db.collection(matchesCollection)
                .whereField("userIds", arrayContains: userId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("MatchService: Error listening to matches — \(error.localizedDescription)")
                        return
                    }
                    let matches = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Match.self)
                    } ?? []
                    continuation.yield(matches)
                }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
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
