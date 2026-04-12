//  ImportedPlaylistDetailView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - ImportedPlaylistDetailView

/// Shows the songs inside an imported Apple Music playlist.
/// Users can tap any song to play it with the full playlist as the queue.
struct ImportedPlaylistDetailView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var songs: [Song] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    let playlist: ImportedPlaylist
    let playerViewModel: PlayerViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView(String(localized: "Loading songs..."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if songs.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Songs"),
                    systemImage: "music.note",
                    description: Text(String(localized: "This playlist doesn't contain any songs."))
                )
            } else {
                songList
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTracks()
        }
        .refreshable {
            await loadTracks()
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Helpers

    /// Checks whether the given song is currently playing.
    /// Compares by ID first; falls back to title + artist match because
    /// library songs (`i.xxx`) and catalog songs (`1234567890`) have
    /// different IDs even when they represent the same track.
    private func isNowPlaying(_ song: Song) -> Bool {
        guard let current = playerViewModel.currentSong else { return false }
        if current.id == song.id { return true }
        return current.title == song.title && current.artistName == song.artistName
    }

    // MARK: - Song List

    private var songList: some View {
        List {
            // Playlist header
            playlistHeader
                .listRowSeparator(.hidden)

            // Songs
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                let nowPlaying = isNowPlaying(song)

                Button {
                    Task { await playerViewModel.play(song: song, in: songs) }
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundStyle(nowPlaying ? AnyShapeStyle(.musicRed) : AnyShapeStyle(.secondary))
                            .frame(width: 24)

                        if let artwork = song.artwork {
                            ArtworkImage(artwork, width: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.musicRed.opacity(0.2))
                                .frame(width: 48, height: 48)
                                .overlay {
                                    Image(systemName: "music.note")
                                        .font(.caption)
                                        .foregroundStyle(.musicRed)
                                }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(song.title)
                                .font(.body)
                                .foregroundStyle(nowPlaying ? AnyShapeStyle(.musicRed) : AnyShapeStyle(.primary))
                                .lineLimit(1)

                            Text(song.artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        if nowPlaying && playerViewModel.isPlaying {
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
                .accessibilityLabel(String(localized: nowPlaying ? "Now playing: \(song.title) by \(song.artistName)" : "Play \(song.title) by \(song.artistName)"))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Playlist Header

    private var playlistHeader: some View {
        VStack(spacing: 12) {
            // Artwork
            playlistArtwork
                .frame(width: 180, height: 180)

            // Name
            Text(playlist.name)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Curator / description
            if let curator = playlist.curatorName {
                Text(curator)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Song count
            Text(String(localized: "\(songs.count) songs"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Playlist Artwork

    @ViewBuilder
    private var playlistArtwork: some View {
        if let urlString = playlist.artworkURL,
           let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 8, y: 4)
            } placeholder: {
                artworkPlaceholder
            }
        } else {
            artworkPlaceholder
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.musicRed.opacity(0.15))
            .frame(width: 180, height: 180)
            .overlay {
                Image(systemName: "music.note.list")
                    .font(.largeTitle)
                    .foregroundStyle(.musicRed)
            }
    }

    // MARK: - Load Tracks

    private func loadTracks() async {
        isLoading = true
        errorMessage = nil
        do {
            songs = try await services.musicService.fetchPlaylistTracks(playlistId: playlist.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
