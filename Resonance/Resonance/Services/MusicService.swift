//  MusicService.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - MusicService

@MainActor
final class MusicService: MusicServiceProtocol {

    // MARK: - Authorization

    /// Requests MusicKit authorization from the user.
    /// - Returns: The resulting `MusicAuthorization.Status`.
    @discardableResult
    func requestAuthorization() async -> MusicAuthorization.Status {
        await MusicAuthorization.request()
    }

    /// Returns the current MusicKit authorization status.
    var authorizationStatus: MusicAuthorization.Status {
        MusicAuthorization.currentStatus
    }

    // MARK: - Search

    /// Searches the Apple Music catalog for songs matching a query.
    /// - Parameters:
    ///   - query: The search term.
    ///   - limit: Maximum number of results.
    /// - Returns: An array of `Song`.
    func searchSongs(query: String, limit: Int = 25) async throws -> [Song] {
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = limit
        let response = try await request.response()
        return Array(response.songs)
    }

    /// Searches the Apple Music catalog for artists matching a query.
    /// - Parameters:
    ///   - query: The search term.
    ///   - limit: Maximum number of results.
    /// - Returns: An array of `Artist`.
    func searchArtists(query: String, limit: Int = 25) async throws -> [Artist] {
        var request = MusicCatalogSearchRequest(term: query, types: [Artist.self])
        request.limit = limit
        let response = try await request.response()
        return Array(response.artists)
    }

    // MARK: - Charts

    /// Fetches the most played song charts from the Apple Music catalog.
    /// - Returns: An array of `MusicCatalogChart<Song>`.
    func fetchTopSongs() async throws -> [MusicCatalogChart<Song>] {
        let request = MusicCatalogChartsRequest(kinds: [.mostPlayed], types: [Song.self])
        let response = try await request.response()
        return response.songCharts
    }

    /// Fetches daily global top song charts.
    /// - Returns: An array of `MusicCatalogChart<Song>`.
    func fetchDailyTopSongs() async throws -> [MusicCatalogChart<Song>] {
        let request = MusicCatalogChartsRequest(kinds: [.dailyGlobalTop], types: [Song.self])
        let response = try await request.response()
        return response.songCharts
    }

    // MARK: - Recently Played

    /// Fetches the user's recently played songs.
    /// - Returns: An array of `Song`.
    func fetchRecentlyPlayed() async throws -> [Song] {
        let request = MusicRecentlyPlayedRequest<Song>()
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - In-App Playback (ApplicationMusicPlayer)

    /// Plays a song using the application music player.
    /// - Parameter song: The `Song` to play.
    func play(song: Song) async throws {
        let player = ApplicationMusicPlayer.shared
        player.queue = [song]
        try await player.play()
    }

    /// Pauses the application music player.
    func pause() {
        ApplicationMusicPlayer.shared.pause()
    }

    /// Resumes playback on the application music player.
    func resume() async throws {
        try await ApplicationMusicPlayer.shared.play()
    }

    /// Skips to the next song in the queue.
    func skipToNext() async throws {
        try await ApplicationMusicPlayer.shared.skipToNextEntry()
    }

    /// Skips to the previous song in the queue.
    func skipToPrevious() async throws {
        try await ApplicationMusicPlayer.shared.skipToPreviousEntry()
    }

    // MARK: - Now Playing (ApplicationMusicPlayer)

    /// Returns the currently playing entry from the application music player, if any.
    var nowPlayingEntry: ApplicationMusicPlayer.Queue.Entry? {
        ApplicationMusicPlayer.shared.queue.currentEntry
    }

    /// Returns the current playback status of the application music player.
    var appPlaybackStatus: MusicPlayer.PlaybackStatus {
        ApplicationMusicPlayer.shared.state.playbackStatus
    }

    // MARK: - External Playback Detection (SystemMusicPlayer)

    /// Returns the currently playing entry from the system music player (Apple Music app), if any.
    var systemNowPlayingEntry: SystemMusicPlayer.Queue.Entry? {
        SystemMusicPlayer.shared.queue.currentEntry
    }

    /// Returns the current playback status of the system music player (Apple Music app).
    var systemPlaybackStatus: MusicPlayer.PlaybackStatus {
        SystemMusicPlayer.shared.state.playbackStatus
    }

    /// Returns the song currently playing on the system music player, if any.
    /// Use this to detect what users are listening to in the Apple Music app.
    var systemNowPlayingSong: Song? {
        guard let entry = systemNowPlayingEntry,
              case .song(let song) = entry.item else {
            return nil
        }
        return song
    }

    /// Returns `true` if the system music player is currently playing.
    var isSystemPlayerPlaying: Bool {
        systemPlaybackStatus == .playing
    }

    // MARK: - Unified Now Playing

    /// Returns the song currently playing across either player.
    /// Prefers the application player (in-app) if it is actively playing;
    /// otherwise falls back to the system player (Apple Music app).
    var currentlyPlayingSong: Song? {
        // Prefer in-app player if it's actively playing
        if appPlaybackStatus == .playing,
           let entry = nowPlayingEntry,
           case .song(let song) = entry.item {
            return song
        }
        // Fall back to system player (external Apple Music)
        if isSystemPlayerPlaying {
            return systemNowPlayingSong
        }
        // If neither is playing, check if in-app has a paused entry
        if let entry = nowPlayingEntry,
           case .song(let song) = entry.item {
            return song
        }
        return nil
    }

    /// Returns `true` if either player is currently playing.
    var isAnyPlayerPlaying: Bool {
        appPlaybackStatus == .playing || isSystemPlayerPlaying
    }

    // MARK: - Conversion Helpers

    /// Converts a MusicKit `Song` to a lightweight `MusicItem`.
    nonisolated func musicItem(from song: Song) -> MusicItem {
        MusicItem(
            id: song.id.rawValue,
            name: song.title,
            artistName: song.artistName,
            artworkURL: song.artwork?.url(width: 300, height: 300),
            genre: song.genreNames.first,
            durationInSeconds: song.duration.map { Int($0) }
        )
    }

    /// Converts a MusicKit `Song` to a `ListeningSession`.
    nonisolated func listeningSession(from song: Song) -> ListeningSession {
        ListeningSession(
            songId: song.id.rawValue,
            songName: song.title,
            artistId: song.artistURL?.absoluteString ?? song.id.rawValue,
            artistName: song.artistName,
            genre: song.genreNames.first,
            listenedAt: Date(),
            durationSeconds: song.duration.map { Int($0) } ?? 0
        )
    }
}
