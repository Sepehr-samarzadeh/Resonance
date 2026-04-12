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
    var suggestions: [Song] = []
    var isSearching = false
    var errorMessage: String?

    private let musicService: any MusicServiceProtocol

    /// Task handle for the current search, so we can cancel on new input.
    private var searchTask: Task<Void, Never>?

    /// Task handle for suggestions, cancelled independently from full search.
    private var suggestionTask: Task<Void, Never>?

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
            suggestions = []
            isSearching = false
            return
        }

        // Fetch suggestions quickly (shorter debounce)
        fetchSuggestions(for: trimmed)

        isSearching = true
        searchTask = Task {
            // Debounce — wait 400ms before executing full results
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }

            do {
                let songs = try await musicService.searchSongs(query: trimmed, limit: 20)
                guard !Task.isCancelled else { return }
                songResults = songs
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }

            isSearching = false
        }
    }

    // MARK: - Submit Search

    /// Called when the user submits their search (taps Search on keyboard).
    func submitSearch() {
        searchTask?.cancel()
        suggestionTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        searchTask = Task {
            do {
                songResults = try await musicService.searchSongs(query: trimmed, limit: 20)
                suggestions = []
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    // MARK: - Suggestions

    /// Fetches a small set of song suggestions with a shorter debounce.
    private func fetchSuggestions(for query: String) {
        suggestionTask?.cancel()
        suggestionTask = Task {
            // Short debounce for responsiveness
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            do {
                let results = try await musicService.searchSongs(query: query, limit: 5)
                guard !Task.isCancelled else { return }
                suggestions = results
            } catch {
                // Suggestions are best-effort; don't show errors
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Select Suggestion

    /// Called when the user taps a suggestion to fill the search bar.
    func selectSuggestion(_ song: Song) {
        query = song.title
        suggestions = []
        search()
    }
}
