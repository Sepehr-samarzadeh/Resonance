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

    /// Returns the current MusicKit authorization status.
    var authorizationStatus: MusicAuthorization.Status { get }

    /// Searches the Apple Music catalog for songs matching a query.
    func searchSongs(query: String, limit: Int) async throws -> [Song]

    /// Searches the Apple Music catalog for artists matching a query.
    func searchArtists(query: String, limit: Int) async throws -> [Artist]

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

    /// Returns `true` when the system (Apple Music) player is the active source.
    var isSystemPlayerActive: Bool { get }

    /// Pauses the system music player.
    func pauseSystem()

    /// Resumes the system music player.
    func resumeSystem() async throws

    /// Skips to the next song on the system music player.
    func skipToNextSystem() async throws

    /// Skips to the previous song on the system music player.
    func skipToPreviousSystem() async throws

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

    /// The current playback time (position) of the active player, in seconds.
    var playbackTime: TimeInterval { get }

    /// The duration of the currently playing song, in seconds.
    /// Returns `nil` when no song is loaded.
    var currentSongDuration: TimeInterval? { get }

    /// Seeks to a specific time (in seconds) on the active player.
    func seek(to time: TimeInterval) async throws

    /// Fetches the current user's Apple Music social profile photo URL.
    /// Returns `nil` if the user has no social profile or no profile picture set.
    func fetchProfilePhotoURL(width: Int, height: Int) async throws -> URL?
}
