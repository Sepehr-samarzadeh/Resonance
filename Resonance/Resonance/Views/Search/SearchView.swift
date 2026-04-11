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

/// Main search content with search bar and results.
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

            if !viewModel.artistResults.isEmpty {
                Section(String(localized: "Artists")) {
                    ForEach(viewModel.artistResults) { artist in
                        SearchArtistRow(artist: artist)
                    }
                }
            }

            if !viewModel.songResults.isEmpty {
                Section(String(localized: "Songs")) {
                    ForEach(viewModel.songResults) { song in
                        SearchSongRow(
                            song: song,
                            playerViewModel: playerViewModel
                        )
                    }
                }
            }

            if !viewModel.isSearching
                && viewModel.songResults.isEmpty
                && viewModel.artistResults.isEmpty
                && !viewModel.query.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
        .listStyle(.plain)
        .searchable(
            text: $viewModel.query,
            prompt: String(localized: "Songs, Artists")
        )
        .onChange(of: viewModel.query) {
            viewModel.search()
        }
        .overlay {
            if viewModel.query.isEmpty
                && viewModel.songResults.isEmpty
                && viewModel.artistResults.isEmpty {
                ContentUnavailableView(
                    String(localized: "Search Apple Music"),
                    systemImage: "magnifyingglass",
                    description: Text(String(localized: "Find songs and artists to play."))
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

// MARK: - SearchSongRow

/// A tappable song row in search results that plays the song.
struct SearchSongRow: View {
    let song: Song
    let playerViewModel: PlayerViewModel

    var body: some View {
        Button {
            Task { await playerViewModel.play(song: song) }
        } label: {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "play.circle")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Play \(song.title) by \(song.artistName)"))
        .sensoryFeedback(.impact(flexibility: .soft), trigger: playerViewModel.currentSong?.id)
    }
}

// MARK: - SearchArtistRow

/// Displays an artist in search results.
struct SearchArtistRow: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: 12) {
            if let artwork = artist.artwork {
                ArtworkImage(artwork, width: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.purple.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "music.mic")
                            .foregroundStyle(.purple)
                    }
                    .accessibilityHidden(true)
            }

            Text(artist.name)
                .font(.body)
                .lineLimit(1)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
