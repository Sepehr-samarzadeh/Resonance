//  PlayerViewModel.swift
//  Resonance

import Foundation
import MusicKit
import OSLog

// MARK: - PlayerViewModel

@MainActor
@Observable
final class PlayerViewModel {

    // MARK: - Properties

    var isPlaying = false
    var currentSong: Song?
    var queue: [Song] = []
    var errorMessage: String?
    var playbackTime: TimeInterval = 0
    var songDuration: TimeInterval?

    private let musicService: any MusicServiceProtocol
    private let userService: any UserServiceProtocol

    /// Task handle for the continuous now-playing observer.
    private var nowPlayingTask: Task<Void, Never>?

    /// Task handle for the playback-time polling timer.
    private var playbackTimerTask: Task<Void, Never>?

    // MARK: - Init

    init(musicService: some MusicServiceProtocol, userService: some UserServiceProtocol) {
        self.musicService = musicService
        self.userService = userService
    }

    // MARK: - Playback Controls

    /// Plays a specific song using the in-app player.
    func play(song: Song) async {
        do {
            try await musicService.play(song: song)
            currentSong = song
            isPlaying = true
            songDuration = song.duration
            playbackTime = 0
            queue = [song]
            startPlaybackTimerIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Plays a song from a list, populating the full queue so skip works.
    /// - Parameters:
    ///   - song: The song to start playing.
    ///   - songs: The full list of songs to enqueue.
    func play(song: Song, in songs: [Song]) async {
        let index = songs.firstIndex(where: { $0.id == song.id }) ?? 0
        do {
            try await musicService.play(songs: songs, startingAt: index)
            currentSong = song
            isPlaying = true
            songDuration = song.duration
            playbackTime = 0
            queue = songs
            startPlaybackTimerIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Pauses whichever player is currently active.
    func pause() {
        if musicService.isSystemPlayerActive {
            musicService.pauseSystem()
        } else {
            musicService.pause()
        }
        isPlaying = false
    }

    /// Resumes whichever player is currently active.
    func resume() async {
        do {
            if musicService.isSystemPlayerActive {
                try await musicService.resumeSystem()
            } else {
                try await musicService.resume()
            }
            isPlaying = true
            startPlaybackTimerIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles between play and pause on the active player.
    func togglePlayback() async {
        if isPlaying {
            pause()
        } else {
            await resume()
        }
    }

    /// Skips to the next song on the active player.
    ///
    /// After the skip completes, waits briefly for MusicKit's queue entry to
    /// update, then forces a manual sync. The `nowPlayingChanges()` observer
    /// often fires *before* the queue entry reflects the new song, so relying
    /// on it alone can leave stale artwork/metadata on screen.
    func skipToNext() async {
        do {
            if musicService.isSystemPlayerActive {
                try await musicService.skipToNextSystem()
            } else {
                try await musicService.skipToNext()
            }
            await waitAndSync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Skips to the previous song on the active player.
    ///
    /// Applies the same post-skip sync strategy as `skipToNext()`.
    func skipToPrevious() async {
        do {
            if musicService.isSystemPlayerActive {
                try await musicService.skipToPreviousSystem()
            } else {
                try await musicService.skipToPrevious()
            }
            await waitAndSync()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Waits for MusicKit's queue entry to settle after a skip, then forces
    /// a `syncNowPlaying()` call. Retries up to 3 times if the song hasn't
    /// changed, to handle slow queue updates.
    private func waitAndSync() async {
        let previousSongId = currentSong?.id
        for attempt in 1...3 {
            try? await Task.sleep(for: .milliseconds(150 * attempt))
            syncNowPlaying()
            if currentSong?.id != previousSongId {
                break
            }
        }
        startPlaybackTimerIfNeeded()
    }

    /// Seeks to a specific time in the current song.
    func seek(to time: TimeInterval) async {
        do {
            try await musicService.seek(to: time)
            playbackTime = time
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Now Playing Observation

    /// Starts observing playback state changes from both the in-app player
    /// and the system player using MusicKit's change notifications.
    ///
    /// Debounces rapid updates (e.g. playback-position ticks) to avoid
    /// overwhelming SwiftUI with re-renders.
    func startObservingNowPlaying() {
        stopObservingNowPlaying()
        nowPlayingTask = Task { [weak self] in
            guard let self else { return }
            // Sync once immediately
            self.syncNowPlaying()
            for await _ in self.musicService.nowPlayingChanges() {
                guard !Task.isCancelled else { break }
                self.syncNowPlaying()
                self.startPlaybackTimerIfNeeded()
                // Throttle: wait a short interval before processing the
                // next change notification so we don't re-render on every
                // playback-position tick (~1 Hz or faster).
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        startPlaybackTimerIfNeeded()
    }

    /// Stops the continuous now-playing observer.
    func stopObservingNowPlaying() {
        nowPlayingTask?.cancel()
        nowPlayingTask = nil
        playbackTimerTask?.cancel()
        playbackTimerTask = nil
    }

    /// Starts a 1-second polling timer to update `playbackTime` while playing.
    /// MusicKit's `objectWillChange` does not fire on playback position advances,
    /// so we need an independent timer to keep the progress bar moving.
    private func startPlaybackTimerIfNeeded() {
        // Don't start if already running
        guard playbackTimerTask == nil || playbackTimerTask?.isCancelled == true else { return }
        playbackTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self else { break }
                guard self.isPlaying else {
                    // Stop polling when paused — will restart on next state change
                    self.playbackTimerTask = nil
                    return
                }
                let newTime = self.musicService.playbackTime
                if abs(self.playbackTime - newTime) > 0.5 {
                    self.playbackTime = newTime
                }
                let newDuration = self.musicService.currentSongDuration
                if self.songDuration != newDuration {
                    self.songDuration = newDuration
                }
            }
        }
    }

    /// Syncs the current now-playing state from both the in-app and system music players.
    /// Prefers the in-app player if it is actively playing; otherwise checks the system
    /// player to detect external Apple Music playback for real-time matching.
    ///
    /// Only mutates properties when the value has actually changed, to avoid
    /// triggering unnecessary `@Observable` notifications that would re-render
    /// every view observing this model.
    private func syncNowPlaying() {
        let newSong = musicService.currentlyPlayingSong
        let newIsPlaying = musicService.isAnyPlayerPlaying
        let newPlaybackTime = musicService.playbackTime
        let newDuration = musicService.currentSongDuration

        if currentSong?.id != newSong?.id {
            currentSong = newSong
        }
        if isPlaying != newIsPlaying {
            isPlaying = newIsPlaying
        }
        if abs(playbackTime - newPlaybackTime) > 0.5 {
            playbackTime = newPlaybackTime
        }
        if songDuration != newDuration {
            songDuration = newDuration
        }
    }

    // MARK: - Save Listening Session

    /// Records the current song as a listening session.
    func saveListeningSession(userId: String) async {
        guard let song = currentSong else { return }
        let session = musicService.listeningSession(from: song)
        do {
            try await userService.saveListeningSession(userId: userId, session: session)
        } catch {
            Log.music.error("Failed to save listening session: \(error.localizedDescription)")
        }
    }
}
