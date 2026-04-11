//  SearchViewModel.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - SearchViewModel

@MainActor
@Observable
final class SearchViewModel {

    // MARK: - Properties

    var query = ""
    var songResults: [Song] = []
    var artistResults: [Artist] = []
    var isSearching = false
    var errorMessage: String?

    private let musicService: any MusicServiceProtocol

    /// Task handle for the current search, so we can cancel on new input.
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(musicService: some MusicServiceProtocol) {
        self.musicService = musicService
    }

    // MARK: - Search

    /// Triggers a debounced search. Call this from `onChange(of: query)`.
    func search() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            songResults = []
            artistResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            // Debounce — wait 400ms before executing
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                async let songs = musicService.searchSongs(query: trimmed, limit: 20)
                async let artists = musicService.searchArtists(query: trimmed, limit: 10)
                let (fetchedSongs, fetchedArtists) = try await (songs, artists)

                guard !Task.isCancelled else { return }
                songResults = fetchedSongs
                artistResults = fetchedArtists
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isSearching = false
        }
    }
}
