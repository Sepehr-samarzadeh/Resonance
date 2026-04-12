//  HomeViewModel.swift
//  Resonance

import Foundation
import MusicKit
import OSLog

// MARK: - HomeViewModel

@MainActor
@Observable
final class HomeViewModel {

    // MARK: - Properties

    var recentlyPlayed: [Song] = []
    var chartPreview: [Song] = []
    var featuredArtists: [FeaturedArtist] = []
    var isLoading = false
    var errorMessage: String?
    var musicAuthStatus: MusicAuthorization.Status = .notDetermined

    private let musicService: any MusicServiceProtocol
    private let userService: any UserServiceProtocol

    // MARK: - Init

    init(musicService: some MusicServiceProtocol, userService: some UserServiceProtocol) {
        self.musicService = musicService
        self.userService = userService
        self.musicAuthStatus = musicService.authorizationStatus
    }

    // MARK: - Load Data

    /// Loads the home screen data including recently played songs,
    /// chart preview, and featured artists.
    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Request authorization if not yet determined
        if musicAuthStatus == .notDetermined {
            musicAuthStatus = await musicService.requestAuthorization()
        }

        guard musicAuthStatus == .authorized else {
            isLoading = false
            return
        }

        do {
            async let recentTask = musicService.fetchRecentlyPlayed()
            async let chartsTask = musicService.fetchTopSongs()

            let (recent, charts) = try await (recentTask, chartsTask)

            recentlyPlayed = recent
            chartPreview = Array(charts.first?.items.prefix(4) ?? [])
            featuredArtists = extractFeaturedArtists(from: recent)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Extract Featured Artists

    /// Extracts unique artists from recently played songs.
    private func extractFeaturedArtists(from songs: [Song]) -> [FeaturedArtist] {
        var seen = Set<String>()
        var artists: [FeaturedArtist] = []

        for song in songs {
            let name = song.artistName
            guard !seen.contains(name) else { continue }
            seen.insert(name)

            artists.append(FeaturedArtist(
                id: name,
                name: name,
                artwork: song.artwork
            ))

            if artists.count >= 10 { break }
        }

        return artists
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
                    artworkURL: song.artwork?.url(width: 300, height: 300)?.absoluteString,
                    startedAt: Date()
                )
                try await userService.updateCurrentlyListening(userId: userId, listening: listening)
            } else {
                try await userService.updateCurrentlyListening(userId: userId, listening: nil)
            }
        } catch {
            Log.music.error("Failed to update currently listening: \(error.localizedDescription)")
        }
    }
}
