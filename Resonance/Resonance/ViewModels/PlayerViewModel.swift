//  PlayerViewModel.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - PlayerViewModel

@MainActor
@Observable
final class PlayerViewModel {

    // MARK: - Properties

    var isPlaying = false
    var currentSong: Song?
    var queue: [Song] = []
    var errorMessage: String?

    private let musicService: MusicService
    private let userService: UserService

    /// Task handle for the continuous now-playing observer.
    private var nowPlayingTask: Task<Void, Never>?

    // MARK: - Init

    init(musicService: MusicService, userService: UserService) {
        self.musicService = musicService
        self.userService = userService
    }

    // MARK: - Playback Controls

    /// Plays a specific song.
    func play(song: Song) async {
        do {
            try await musicService.play(song: song)
            currentSong = song
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Pauses the current playback.
    func pause() {
        musicService.pause()
        isPlaying = false
    }

    /// Resumes playback.
    func resume() async {
        do {
            try await musicService.resume()
            isPlaying = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Toggles between play and pause.
    func togglePlayback() async {
        if isPlaying {
            pause()
        } else {
            await resume()
        }
    }

    /// Skips to the next song.
    func skipToNext() async {
        do {
            try await musicService.skipToNext()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Skips to the previous song.
    func skipToPrevious() async {
        do {
            try await musicService.skipToPrevious()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Now Playing Observation

    /// Starts continuously observing the now-playing state from both
    /// the in-app player and the system player (Apple Music app).
    func startObservingNowPlaying() {
        stopObservingNowPlaying()
        nowPlayingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.syncNowPlaying()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    /// Stops the continuous now-playing observer.
    func stopObservingNowPlaying() {
        nowPlayingTask?.cancel()
        nowPlayingTask = nil
    }

    /// Syncs the current now-playing state from both the in-app and system music players.
    /// Prefers the in-app player if it is actively playing; otherwise checks the system
    /// player to detect external Apple Music playback for real-time matching.
    private func syncNowPlaying() {
        currentSong = musicService.currentlyPlayingSong
        isPlaying = musicService.isAnyPlayerPlaying
    }

    // MARK: - Save Listening Session

    /// Records the current song as a listening session.
    func saveListeningSession(userId: String) async {
        guard let song = currentSong else { return }
        let session = musicService.listeningSession(from: song)
        do {
            try await userService.saveListeningSession(userId: userId, session: session)
        } catch {
            print("PlayerViewModel: Failed to save listening session — \(error.localizedDescription)")
        }
    }
}
