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

    private let musicService = MusicService()
    private let userService = UserService()

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

    /// Observes the now-playing state and updates the current song.
    func observeNowPlaying() {
        let entry = musicService.nowPlayingEntry
        if let entry, case .song(let song) = entry.item {
            currentSong = song
        }
        isPlaying = musicService.playbackStatus == .playing
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
