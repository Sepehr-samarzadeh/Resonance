//  MusicChartViewModel.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - MusicChartViewModel

@MainActor
@Observable
final class MusicChartViewModel {

    // MARK: - Properties

    var songCharts: [MusicCatalogChart<Song>] = []
    var isLoading = false
    var errorMessage: String?

    private let musicService: MusicService

    // MARK: - Init

    init(musicService: MusicService) {
        self.musicService = musicService
    }

    // MARK: - Fetch Charts

    /// Fetches the most played song charts from the Apple Music catalog.
    func fetchCharts() async {
        isLoading = true
        errorMessage = nil

        do {
            songCharts = try await musicService.fetchTopSongs()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
