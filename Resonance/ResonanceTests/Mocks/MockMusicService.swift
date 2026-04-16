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
    var isSystemPlayerActive = false
    var authorizationStatus: MusicAuthorization.Status = .authorized
    var playbackTime: TimeInterval = 0
    var currentSongDuration: TimeInterval?

    // MARK: - Call Tracking

    var requestAuthorizationCallCount = 0
    var searchSongsCallCount = 0
    var searchArtistsCallCount = 0
    var fetchTopSongsCallCount = 0
    var fetchRecentlyPlayedCallCount = 0
    var playCallCount = 0
    var pauseCallCount = 0
    var resumeCallCount = 0
    var skipToNextCallCount = 0
    var skipToPreviousCallCount = 0
    var pauseSystemCallCount = 0
    var resumeSystemCallCount = 0
    var skipToNextSystemCallCount = 0
    var skipToPreviousSystemCallCount = 0

    // MARK: - Stubbed Results

    var stubbedAuthorizationStatus: MusicAuthorization.Status = .authorized
    var stubbedSearchSongsResult: Result<[Song], Error> = .success([])
    var stubbedSearchArtistsResult: Result<[Artist], Error> = .success([])
    var stubbedFetchTopSongsResult: Result<[MusicCatalogChart<Song>], Error> = .success([])
    var stubbedFetchRecentlyPlayedResult: Result<[Song], Error> = .success([])
    var stubbedPlayError: Error?
    var stubbedResumeError: Error?
    var stubbedSkipToNextError: Error?
    var stubbedSkipToPreviousError: Error?
    var stubbedResumeSystemError: Error?
    var stubbedSkipToNextSystemError: Error?
    var stubbedSkipToPreviousSystemError: Error?
    var seekCallCount = 0

    // MARK: - Profile Photo

    var fetchProfilePhotoURLCallCount = 0
    var stubbedProfilePhotoURL: URL?

    /// Continuation exposed so tests can yield values into the now-playing stream.
    var nowPlayingContinuation: AsyncStream<Void>.Continuation?

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
        artworkURL: nil,
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

    func searchArtists(query: String, limit: Int) async throws -> [Artist] {
        searchArtistsCallCount += 1
        return try stubbedSearchArtistsResult.get()
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

    func pauseSystem() {
        pauseSystemCallCount += 1
    }

    func resumeSystem() async throws {
        resumeSystemCallCount += 1
        if let error = stubbedResumeSystemError { throw error }
    }

    func skipToNextSystem() async throws {
        skipToNextSystemCallCount += 1
        if let error = stubbedSkipToNextSystemError { throw error }
    }

    func skipToPreviousSystem() async throws {
        skipToPreviousSystemCallCount += 1
        if let error = stubbedSkipToPreviousSystemError { throw error }
    }

    func nowPlayingChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            self.nowPlayingContinuation = continuation
        }
    }

    nonisolated func musicItem(from song: Song) -> Resonance.MusicItem {
        stubbedMusicItem
    }

    nonisolated func listeningSession(from song: Song) -> ListeningSession {
        stubbedListeningSession
    }

    func seek(to time: TimeInterval) async throws {
        seekCallCount += 1
        playbackTime = time
    }

    func fetchProfilePhotoURL(width: Int, height: Int) async throws -> URL? {
        fetchProfilePhotoURLCallCount += 1
        return stubbedProfilePhotoURL
    }

    // MARK: - Artwork URLs

    var fetchArtworkURLsCallCount = 0
    var stubbedArtworkURLs: [String: String] = [:]

    func fetchArtworkURLs(for songIds: [String], width: Int, height: Int) async throws -> [String: String] {
        fetchArtworkURLsCallCount += 1
        return stubbedArtworkURLs
    }

    // MARK: - Library

    var fetchUserPlaylistsCallCount = 0
    var stubbedUserPlaylists: [Playlist] = []
    var fetchPlaylistTracksCallCount = 0
    var stubbedPlaylistTracks: [Song] = []
    var fetchLibraryArtistNamesCallCount = 0
    var stubbedLibraryArtistNames: [String] = []

    func fetchUserPlaylists() async throws -> [Playlist] {
        fetchUserPlaylistsCallCount += 1
        return stubbedUserPlaylists
    }

    func fetchPlaylistTracks(playlistId: String) async throws -> [Song] {
        fetchPlaylistTracksCallCount += 1
        return stubbedPlaylistTracks
    }

    func fetchLibraryArtistNames(limit: Int) async throws -> [String] {
        fetchLibraryArtistNamesCallCount += 1
        return stubbedLibraryArtistNames
    }

    func play(songs: [Song], startingAt index: Int) async throws {
        playCallCount += 1
        if let error = stubbedPlayError { throw error }
    }
}
