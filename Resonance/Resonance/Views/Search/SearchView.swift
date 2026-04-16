//  SearchView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - SearchView

struct SearchView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: SearchViewModel?
    let playerViewModel: PlayerViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                SearchContentView(
                    viewModel: viewModel,
                    playerViewModel: playerViewModel
                )
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Search"))
        .task {
            if viewModel == nil {
                viewModel = SearchViewModel(musicService: services.musicService)
            }
        }
    }
}

// MARK: - SearchContentView

/// Main search content with search bar, suggestions, and results.
private struct SearchContentView: View {

    @Bindable var viewModel: SearchViewModel
    let playerViewModel: PlayerViewModel

    var body: some View {
        List {
            if viewModel.isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if !viewModel.songResults.isEmpty {
                Section(String(localized: "Songs")) {
                    ForEach(viewModel.songResults) { song in
                        SearchSongRow(
                            song: song,
                            allSongs: viewModel.songResults,
                            playerViewModel: playerViewModel
                        )
                    }
                }
            }

            if !viewModel.isSearching
                && viewModel.songResults.isEmpty
                && !viewModel.query.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
        .listStyle(.plain)
        .searchable(
            text: $viewModel.query,
            prompt: String(localized: "Search songs")
        )
        .searchSuggestions {
            if !viewModel.suggestions.isEmpty {
                ForEach(Array(viewModel.suggestions.enumerated()), id: \.element.id) { index, song in
                    SearchSuggestionRow(song: song)
                        .searchCompletion(song.title)
                        .transition(
                            .asymmetric(
                                insertion: .opacity
                                    .combined(with: .move(edge: .bottom))
                                    .animation(.spring(duration: 0.35, bounce: 0.2).delay(Double(index) * 0.05)),
                                removal: .opacity.animation(.easeOut(duration: 0.15))
                            )
                        )
                }
            }
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
        .onChange(of: viewModel.query) {
            viewModel.search()
        }
        .overlay {
            if viewModel.query.isEmpty && viewModel.songResults.isEmpty {
                ContentUnavailableView(
                    String(localized: "Search Apple Music"),
                    systemImage: "magnifyingglass",
                    description: Text(String(localized: "Find songs to play."))
                )
            }
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - SearchSuggestionRow

/// A suggestion row shown while the user is typing.
private struct SearchSuggestionRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 10) {
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.musicRed.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.caption2)
                            .foregroundStyle(.musicRed)
                    }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(song.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "\(song.title) by \(song.artistName)"))
    }
}

// MARK: - SearchSongRow

/// A tappable song row in search results that plays the song.
struct SearchSongRow: View {
    let song: Song
    let allSongs: [Song]
    let playerViewModel: PlayerViewModel

    private var isNowPlaying: Bool {
        playerViewModel.currentSong?.id == song.id
    }

    var body: some View {
        Button {
            Task { await playerViewModel.play(song: song, in: allSongs) }
        } label: {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.body)
                        .foregroundStyle(isNowPlaying ? AnyShapeStyle(.musicRed) : AnyShapeStyle(.primary))
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isNowPlaying && playerViewModel.isPlaying {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundStyle(.musicRed)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                        .accessibilityLabel(String(localized: "Now Playing"))
                } else {
                    Image(systemName: "play.circle")
                        .font(.title3)
                        .foregroundStyle(.musicRed)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: isNowPlaying ? "Now playing: \(song.title) by \(song.artistName)" : "Play \(song.title) by \(song.artistName)"))
        .sensoryFeedback(.impact(flexibility: .soft), trigger: playerViewModel.currentSong?.id)
    }
}
