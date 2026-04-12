//  OnboardingArtistView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - OnboardingArtistView

/// Onboarding step where users search and select favorite artists,
/// and optionally import artist data from their Apple Music library.
struct OnboardingArtistView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @Binding var selectedArtists: [TasteArtist]
    @Binding var libraryArtistNames: [String]
    var onNext: () -> Void

    @State private var searchText = ""
    @State private var searchResults: [Artist] = []
    @State private var isSearching = false
    @State private var libraryScanState: LibraryScanState = .idle
    @State private var searchTask: Task<Void, Never>?
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 60

    private var canProceed: Bool {
        !selectedArtists.isEmpty
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            headerSection

            searchField

            contentSection

            Spacer()

            footerSection
        }
        .padding()
        .animation(.easeOut(duration: 0.2), value: selectedArtists.count)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.musicRed)
                .accessibilityHidden(true)

            Text(String(localized: "Pick Your Artists"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Search for artists you love, or scan your library."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(String(localized: "Search artists..."), text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .onChange(of: searchText) { _, query in
            searchTask?.cancel()
            guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
                searchResults = []
                isSearching = false
                return
            }
            isSearching = true
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                do {
                    let results = try await services.musicService.searchArtists(query: query, limit: 15)
                    guard !Task.isCancelled else { return }
                    searchResults = results
                } catch {
                    if !Task.isCancelled {
                        searchResults = []
                    }
                }
                isSearching = false
            }
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Selected artists chips
                if !selectedArtists.isEmpty {
                    selectedArtistsSection
                }

                // Library scan button
                libraryScanSection

                // Search results
                if !searchText.isEmpty {
                    searchResultsSection
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 320)
    }

    // MARK: - Selected Artists

    private var selectedArtistsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Selected (\(selectedArtists.count))"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(selectedArtists) { artist in
                        selectedArtistChip(artist)
                    }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func selectedArtistChip(_ artist: TasteArtist) -> some View {
        HStack(spacing: 6) {
            Text(artist.name)
                .font(.caption)
                .fontWeight(.semibold)

            Button {
                selectedArtists.removeAll { $0.id == artist.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .accessibilityLabel(String(localized: "Remove \(artist.name)"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.musicRed.opacity(0.2))
        .foregroundStyle(.musicRed)
        .clipShape(Capsule())
    }

    // MARK: - Library Scan

    private var libraryScanSection: some View {
        VStack(spacing: 8) {
            Button {
                Task { await scanLibrary() }
            } label: {
                HStack(spacing: 8) {
                    switch libraryScanState {
                    case .idle:
                        Image(systemName: "music.note.house")
                        Text(String(localized: "Scan Apple Music Library"))
                    case .scanning:
                        ProgressView()
                            .tint(.white)
                        Text(String(localized: "Scanning..."))
                    case .done(let count):
                        Image(systemName: "checkmark.circle.fill")
                        Text(String(localized: "\(count) artists found"))
                    case .failed:
                        Image(systemName: "exclamationmark.triangle")
                        Text(String(localized: "Scan failed — tap to retry"))
                    }
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(libraryScanState == .scanning)
            .padding(.horizontal)

            if case .done = libraryScanState {
                Text(String(localized: "Library artists will be used for matching even if not selected above."))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if searchResults.isEmpty {
                Text(String(localized: "No artists found"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(searchResults, id: \.id) { artist in
                    artistRow(artist)
                }
            }
        }
    }

    private func artistRow(_ artist: Artist) -> some View {
        let isSelected = selectedArtists.contains { $0.id == artist.id.rawValue }

        return Button {
            if isSelected {
                selectedArtists.removeAll { $0.id == artist.id.rawValue }
            } else {
                let artworkURL = artist.artwork?.url(width: 200, height: 200)?.absoluteString
                let tasteArtist = TasteArtist(
                    id: artist.id.rawValue,
                    name: artist.name,
                    artworkURL: artworkURL
                )
                selectedArtists.append(tasteArtist)
            }
        } label: {
            HStack(spacing: 12) {
                if let artwork = artist.artwork {
                    ArtworkImage(artwork, width: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "music.mic")
                                .foregroundStyle(.secondary)
                        }
                }

                Text(artist.name)
                    .font(.body)
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .musicRed : .secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(artist.name)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            if !selectedArtists.isEmpty {
                Text(String(localized: "\(selectedArtists.count) artist(s) selected"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onNext()
            } label: {
                Text(String(localized: "Next"))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canProceed ? .musicRed : .gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canProceed)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Library Scan

    private func scanLibrary() async {
        libraryScanState = .scanning
        do {
            let artistNames = try await services.musicService.fetchLibraryArtistNames(limit: 500)
            libraryArtistNames = artistNames
            libraryScanState = .done(count: artistNames.count)
        } catch {
            libraryScanState = .failed
        }
    }
}

// MARK: - LibraryScanState

private enum LibraryScanState: Equatable {
    case idle
    case scanning
    case done(count: Int)
    case failed
}
