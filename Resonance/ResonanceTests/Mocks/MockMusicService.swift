//  MockMusicService.swift
//  ResonanceTests

import Foundation
import MusicKit
@testable import Resonance

@MainActor
final class MockMusicService: MusicServiceProtocol, @unchecked Sendable {

    // MARK: - Stubbed Properties

    var currentlyPlayingSong: Song?
    var isAnyPlayerPlaying = false

    // MARK: - Call Tracking

    var requestAuthorizationCallCount = 0
    var searchSongsCallCount = 0
    var fetchTopSongsCallCount = 0
    var fetchRecentlyPlayedCallCount = 0
    var playCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var skipToNextCallCount = 0
    var skipToPreviousCallCount = 0

    // MARK: - Stubbed Results

    var stubbedAuthorizationStatus: MusicAuthorization.Status = .authorized
    var stubbedSearchSongsResult: Result<[Song], Error> = .success([])
    var stubbedFetchTopSongsResult: Result<[MusicCatalogChart<Song>], Error> = .success([])
    var stubbedFetchRecentlyPlayedResult: Result<[Song], Error> = .success([])
    var stubbedPlayError: Error?
    var stubbedResumeError: Error?
    var stubbedSkipToNextError: Error?
    var stubbedSkipToPreviousError: Error?

    // MARK: - Stubbed MusicItem/ListeningSession

    /// Stored as `nonisolated(unsafe)` so the `nonisolated` protocol methods
    /// can return them without requiring main-actor isolation.
    nonisolated(unsafe) var stubbedMusicItem = Resonance.MusicItem(
        id: "song-1",
        name: "Test Song",
        artistName: "Test Artist",
        artworkURL: nil,
        genre: "Pop",
        durationInSeconds: 200
    )

    nonisolated(unsafe) var stubbedListeningSession = ListeningSession(
        id: UUID().uuidString,
        songId: "song-1",
        songName: "Test Song",
        artistId: "artist-1",
        artistName: "Test Artist",
        genre: "Pop",
        listenedAt: Date(),
        durationSeconds: 200
    )

    // MARK: - Protocol Methods

    @discardableResult
    func requestAuthorization() async -> MusicAuthorization.Status {
        requestAuthorizationCallCount += 1
        return stubbedAuthorizationStatus
    }

    func searchSongs(query: String, limit: Int) async throws -> [Song] {
        searchSongsCallCount += 1
        return try stubbedSearchSongsResult.get()
    }

    func fetchTopSongs() async throws -> [MusicCatalogChart<Song>] {
        fetchTopSongsCallCount += 1
        return try stubbedFetchTopSongsResult.get()
    }

    func fetchRecentlyPlayed() async throws -> [Song] {
        fetchRecentlyPlayedCallCount += 1
        return try stubbedFetchRecentlyPlayedResult.get()
    }

    func play(song: Song) async throws {
        playCallCount += 1
        if let error = stubbedPlayError { throw error }
    }

    func pause() {
        pauseCallCount += 1
    }

    func resume() async throws {
        resumeCallCount += 1
        if let error = stubbedResumeError { throw error }
    }

    func skipToNext() async throws {
        skipToNextCallCount += 1
        if let error = stubbedSkipToNextError { throw error }
    }

    func skipToPrevious() async throws {
        skipToPreviousCallCount += 1
        if let error = stubbedSkipToPreviousError { throw error }
    }

    nonisolated func musicItem(from song: Song) -> Resonance.MusicItem {
        stubbedMusicItem
    }

    nonisolated func listeningSession(from song: Song) -> ListeningSession {
        stubbedListeningSession
    }
}
