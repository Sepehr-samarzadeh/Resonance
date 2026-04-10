//  HomeViewModel.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - HomeViewModel

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Properties

    var recentlyPlayed: [Song] = []
    var isLoading = false
    var errorMessage: String?

    private let musicService: MusicService
    private let userService: UserService

    // MARK: - Init

    init(musicService: MusicService, userService: UserService) {
        self.musicService = musicService
        self.userService = userService
    }

    // MARK: - Load Data

    /// Loads the home screen data including recently played songs.
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            recentlyPlayed = try await musicService.fetchRecentlyPlayed()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Update Currently Listening

    /// Updates the user's currently listening status in Firestore.
    func updateCurrentlyListening(userId: String, song: Song?) async {
        do {
            if let song {
                let listening = CurrentlyListening(
                    songId: song.id.rawValue,
                    songName: song.title,
                    artistName: song.artistName,
                    startedAt: Date()
                )
                try await userService.updateCurrentlyListening(userId: userId, listening: listening)
            } else {
                try await userService.updateCurrentlyListening(userId: userId, listening: nil)
            }
        } catch {
            print("HomeViewModel: Failed to update currently listening — \(error.localizedDescription)")
        }
    }
}
