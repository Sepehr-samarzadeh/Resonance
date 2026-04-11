//  MusicServiceProtocol.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - MusicServiceProtocol

/// Protocol defining the interface for music playback and discovery services.
/// Used by `HomeViewModel`, `PlayerViewModel`, `ProfileViewModel`,
/// and `MusicChartViewModel` for testability.
@MainActor
protocol MusicServiceProtocol: Sendable {

    /// Requests MusicKit authorization from the user.
    @discardableResult
    func requestAuthorization() async -> MusicAuthorization.Status

    /// Searches the Apple Music catalog for songs matching a query.
    func searchSongs(query: String, limit: Int) async throws -> [Song]

    /// Fetches the most played song charts from the Apple Music catalog.
    func fetchTopSongs() async throws -> [MusicCatalogChart<Song>]

    /// Fetches the user's recently played songs.
    func fetchRecentlyPlayed() async throws -> [Song]

    /// Plays a song using the application music player.
    func play(song: Song) async throws

    /// Pauses the application music player.
    func pause()

    /// Resumes playback on the application music player.
    func resume() async throws

    /// Skips to the next song in the queue.
    func skipToNext() async throws

    /// Skips to the previous song in the queue.
    func skipToPrevious() async throws

    /// Returns the song currently playing across either player.
    var currentlyPlayingSong: Song? { get }

    /// Returns `true` if either player is currently playing.
    var isAnyPlayerPlaying: Bool { get }

    /// Returns an `AsyncStream` that emits a value whenever the playback state
    /// changes on either the in-app or system music player.
    func nowPlayingChanges() -> AsyncStream<Void>

    /// Converts a MusicKit `Song` to a lightweight `MusicItem`.
    nonisolated func musicItem(from song: Song) -> MusicItem

    /// Converts a MusicKit `Song` to a `ListeningSession`.
    nonisolated func listeningSession(from song: Song) -> ListeningSession
}
