//  MusicService.swift
//  Resonance

import Foundation
import MusicKit
import Combine

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

    /// Plays a list of songs starting at a specific index using the application music player.
    /// This populates the full queue so skip next/previous work correctly.
    /// - Parameters:
    ///   - songs: The full list of songs to enqueue.
    ///   - index: The index of the song to start playing.
    func play(songs: [Song], startingAt index: Int) async throws {
        guard !songs.isEmpty else { return }
        let clampedIndex = min(max(index, 0), songs.count - 1)
        let player = ApplicationMusicPlayer.shared
        player.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: songs[clampedIndex])
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

    /// Returns `true` when the system (Apple Music) player is the active source.
    /// The system player is considered active when it is playing, or when the
    /// application player has no queued entry.
    var isSystemPlayerActive: Bool {
        if appPlaybackStatus == .playing { return false }
        if isSystemPlayerPlaying { return true }
        // Neither is playing — system is "active" when app player has nothing queued
        return nowPlayingEntry == nil && systemNowPlayingEntry != nil
    }

    // MARK: - System Player Controls

    /// Pauses the system music player.
    func pauseSystem() {
        SystemMusicPlayer.shared.pause()
    }

    /// Resumes the system music player.
    func resumeSystem() async throws {
        try await SystemMusicPlayer.shared.play()
    }

    /// Skips to the next song on the system music player.
    func skipToNextSystem() async throws {
        try await SystemMusicPlayer.shared.skipToNextEntry()
    }

    /// Skips to the previous song on the system music player.
    func skipToPreviousSystem() async throws {
        try await SystemMusicPlayer.shared.skipToPreviousEntry()
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

    // MARK: - Now Playing Changes Stream

    /// Merges `objectWillChange` from both the application and system music
    /// player states into a single `AsyncStream<Void>` so observers can
    /// react to any playback state change without polling.
    func nowPlayingChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            nonisolated(unsafe) let appSub = ApplicationMusicPlayer.shared.state.objectWillChange
                .sink { _ in continuation.yield() }
            nonisolated(unsafe) let sysSub = SystemMusicPlayer.shared.state.objectWillChange
                .sink { _ in continuation.yield() }

            continuation.onTermination = { @Sendable _ in
                appSub.cancel()
                sysSub.cancel()
            }
        }
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
            artworkURL: song.artwork?.url(width: 300, height: 300)?.absoluteString,
            listenedAt: Date(),
            durationSeconds: song.duration.map { Int($0) } ?? 0
        )
    }

    // MARK: - Playback Position

    /// The current playback time (position) of the active player, in seconds.
    var playbackTime: TimeInterval {
        if isSystemPlayerActive {
            return SystemMusicPlayer.shared.playbackTime
        }
        return ApplicationMusicPlayer.shared.playbackTime
    }

    /// The duration of the currently playing song, in seconds.
    /// Returns `nil` when no song is loaded.
    var currentSongDuration: TimeInterval? {
        currentlyPlayingSong?.duration
    }

    /// Seeks to a specific time (in seconds) on the active player.
    func seek(to time: TimeInterval) async throws {
        if isSystemPlayerActive {
            SystemMusicPlayer.shared.playbackTime = time
        } else {
            ApplicationMusicPlayer.shared.playbackTime = time
        }
    }

    // MARK: - Apple Music Profile Photo

    /// Attempts to fetch the current user's Apple Music profile photo URL.
    /// Currently returns `nil` as Apple has removed the social profile API.
    func fetchProfilePhotoURL(width: Int = 400, height: Int = 400) async throws -> URL? {
        // Apple removed the social profile API (v1/me/social-profile returns 404).
        // No public MusicKit API exposes the user's profile photo.
        return nil
    }

    // MARK: - User Library Playlists

    /// Fetches the user's library playlists from Apple Music.
    /// - Returns: An array of `Playlist` from the user's library.
    func fetchUserPlaylists() async throws -> [Playlist] {
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()
        return Array(response.items)
    }

    // MARK: - User Library Artists

    /// Fetches unique artist names from the user's Apple Music library.
    /// Scans library songs and extracts distinct artist names for taste matching.
    /// - Parameter limit: Maximum number of songs to scan (default 500).
    /// - Returns: An array of unique, lowercased artist names.
    func fetchLibraryArtistNames(limit: Int = 500) async throws -> [String] {
        var request = MusicLibraryRequest<Song>()
        request.limit = limit
        let response = try await request.response()

        var seen = Set<String>()
        var artists: [String] = []

        for song in response.items {
            let normalized = song.artistName.lowercased()
            if seen.insert(normalized).inserted {
                artists.append(normalized)
            }
        }

        return artists
    }

    /// Fetches the tracks (songs) inside a playlist by its ID.
    ///
    /// Library playlists (IDs starting with `p.`) are fetched from the user's
    /// library. Catalog playlists (IDs starting with `pl.`) are fetched from
    /// the Apple Music catalog. Falls back to catalog if the prefix is unknown.
    /// - Parameter playlistId: The `MusicItemID` of the playlist.
    /// - Returns: An array of `Song` contained in the playlist.
    func fetchPlaylistTracks(playlistId: String) async throws -> [Song] {
        if playlistId.hasPrefix("p.") {
            return try await fetchLibraryPlaylistTracks(playlistId: playlistId)
        } else {
            return try await fetchCatalogPlaylistTracks(playlistId: playlistId)
        }
    }

    /// Fetches tracks from a catalog playlist.
    private func fetchCatalogPlaylistTracks(playlistId: String) async throws -> [Song] {
        let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: MusicItemID(playlistId))
        let response = try await request.response()

        guard var playlist = response.items.first else { return [] }

        playlist = try await playlist.with([.tracks])

        guard let tracks = playlist.tracks else { return [] }

        return tracks.compactMap { track -> Song? in
            if case .song(let song) = track {
                return song
            }
            return nil
        }
    }

    /// Fetches tracks from a library playlist (user's own playlists).
    /// Library playlists can't be looked up by ID via `MusicCatalogResourceRequest`,
    /// so we fetch all library playlists and find the matching one.
    private func fetchLibraryPlaylistTracks(playlistId: String) async throws -> [Song] {
        let id = MusicItemID(playlistId)
        let request = MusicLibraryRequest<Playlist>()
        let response = try await request.response()

        guard var playlist = response.items.first(where: { $0.id == id }) else {
            return []
        }

        playlist = try await playlist.with([.tracks])

        guard let tracks = playlist.tracks else { return [] }

        return tracks.compactMap { track -> Song? in
            if case .song(let song) = track {
                return song
            }
            return nil
        }
    }

    // MARK: - Fetch Artwork URLs

    /// Fetches artwork URLs for a batch of song catalog IDs using MusicKit.
    func fetchArtworkURLs(for songIds: [String], width: Int, height: Int) async throws -> [String: String] {
        guard !songIds.isEmpty else { return [:] }

        var result: [String: String] = [:]

        // MusicCatalogResourceRequest supports filtering by multiple IDs
        let musicIds = songIds.map { MusicItemID($0) }
        var request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: musicIds)
        request.limit = songIds.count

        let response = try await request.response()

        for song in response.items {
            if let url = song.artwork?.url(width: width, height: height) {
                result[song.id.rawValue] = url.absoluteString
            }
        }

        return result
    }
}
