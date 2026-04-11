//  MatchServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - MatchServiceProtocol

/// Protocol defining the interface for match discovery and management services.
/// Used by `MatchViewModel` and `ResonanceApp` for testability.
protocol MatchServiceProtocol: Sendable {

    /// Finds users who are currently listening to the same song.
    func findUsersListeningToSong(songId: String, currentUserId: String) async throws -> [String]

    /// Finds users who are currently listening to the same artist.
    func findUsersListeningToArtist(artistName: String, currentUserId: String) async throws -> [String]

    /// Checks if a match already exists between two users (in either direction).
    func findExistingMatch(userId1: String, userId2: String) async throws -> Match?

    /// Creates a real-time match between two users triggered by a song.
    @discardableResult
    func createRealtimeMatch(userId1: String, userId2: String, song: TriggerSong) async throws -> String

    /// Creates a real-time match between two users triggered by an artist.
    @discardableResult
    func createArtistMatch(userId1: String, userId2: String, artist: TriggerArtist) async throws -> String

    /// Fetches a single match by its document ID.
    func fetchMatch(id: String) async throws -> Match?

    /// Fetches all matches for a given user.
    func fetchMatches(userId: String) async throws -> [Match]

    /// Returns an `AsyncStream` that emits match changes for a user in real time.
    func matchChanges(userId: String) -> AsyncStream<[Match]>

    /// Fetches user IDs who have been active recently.
    func fetchRecentUserIds(excluding excludingUserId: String, limit: Int) async throws -> [String]

    /// Creates a historical match between two users if their similarity exceeds the threshold.
    func createHistoricalMatchIfSimilar(userId1: String, userId2: String, threshold: Double) async throws -> String?
}

// MARK: - Default Parameter Values

extension MatchServiceProtocol {

    /// Convenience overload with default threshold of 0.3.
    func createHistoricalMatchIfSimilar(userId1: String, userId2: String) async throws -> String? {
        try await createHistoricalMatchIfSimilar(userId1: userId1, userId2: userId2, threshold: 0.3)
    }
}
