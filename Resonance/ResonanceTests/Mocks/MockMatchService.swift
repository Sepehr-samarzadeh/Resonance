//  MockMatchService.swift
//  ResonanceTests

import Foundation
@testable import Resonance

final class MockMatchService: MatchServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var findUsersListeningToSongCallCount = 0
    var findUsersListeningToArtistCallCount = 0
    var findExistingMatchCallCount = 0
    var createRealtimeMatchCallCount = 0
    var createArtistMatchCallCount = 0
    var fetchMatchCallCount = 0
    var fetchMatchesCallCount = 0
    var fetchMatchesPaginatedCallCount = 0
    var matchChangesCallCount = 0
    var deleteMatchCallCount = 0
    var fetchRecentUserIdsCallCount = 0
    var createHistoricalMatchCallCount = 0

    // MARK: - Stubbed Results

    var stubbedFindUsersListeningToSong: Result<[String], Error> = .success([])
    var stubbedFindUsersListeningToArtist: Result<[String], Error> = .success([])
    var stubbedFindExistingMatch: Result<Match?, Error> = .success(nil)
    var stubbedCreateRealtimeMatch: Result<String, Error> = .success("match-1")
    var stubbedCreateArtistMatch: Result<String, Error> = .success("match-2")
    var stubbedFetchMatch: Result<Match?, Error> = .success(nil)
    var stubbedFetchMatches: Result<[Match], Error> = .success([])
    var stubbedFetchMatchesPaginated: Result<[Match], Error> = .success([])
    var stubbedMatchChanges: [[Match]] = []
    var stubbedDeleteMatchError: Error?
    var stubbedFetchRecentUserIds: Result<[String], Error> = .success([])
    var stubbedCreateHistoricalMatch: Result<String?, Error> = .success(nil)

    // MARK: - Captured Values

    var capturedSongId: String?
    var capturedArtistName: String?

    // MARK: - Protocol Methods

    func findUsersListeningToSong(songId: String, currentUserId: String) async throws -> [String] {
        findUsersListeningToSongCallCount += 1
        capturedSongId = songId
        return try stubbedFindUsersListeningToSong.get()
    }

    func findUsersListeningToArtist(artistName: String, currentUserId: String) async throws -> [String] {
        findUsersListeningToArtistCallCount += 1
        capturedArtistName = artistName
        return try stubbedFindUsersListeningToArtist.get()
    }

    func findExistingMatch(userId1: String, userId2: String) async throws -> Match? {
        findExistingMatchCallCount += 1
        return try stubbedFindExistingMatch.get()
    }

    @discardableResult
    func createRealtimeMatch(userId1: String, userId2: String, song: TriggerSong) async throws -> String {
        createRealtimeMatchCallCount += 1
        return try stubbedCreateRealtimeMatch.get()
    }

    @discardableResult
    func createArtistMatch(userId1: String, userId2: String, artist: TriggerArtist) async throws -> String {
        createArtistMatchCallCount += 1
        return try stubbedCreateArtistMatch.get()
    }

    func fetchMatch(id: String) async throws -> Match? {
        fetchMatchCallCount += 1
        return try stubbedFetchMatch.get()
    }

    func fetchMatches(userId: String) async throws -> [Match] {
        fetchMatchesCallCount += 1
        return try stubbedFetchMatches.get()
    }

    func fetchMatches(userId: String, limit: Int, afterDate: Date?) async throws -> [Match] {
        fetchMatchesPaginatedCallCount += 1
        return try stubbedFetchMatchesPaginated.get()
    }

    func matchChanges(userId: String) -> AsyncStream<[Match]> {
        matchChangesCallCount += 1
        return AsyncStream { continuation in
            for matches in stubbedMatchChanges {
                continuation.yield(matches)
            }
            continuation.finish()
        }
    }

    func deleteMatch(matchId: String) async throws {
        deleteMatchCallCount += 1
        if let error = stubbedDeleteMatchError { throw error }
    }

    func fetchRecentUserIds(excluding excludingUserId: String, limit: Int) async throws -> [String] {
        fetchRecentUserIdsCallCount += 1
        return try stubbedFetchRecentUserIds.get()
    }

    func createHistoricalMatchIfSimilar(userId1: String, userId2: String, threshold: Double) async throws -> String? {
        createHistoricalMatchCallCount += 1
        return try stubbedCreateHistoricalMatch.get()
    }
}
