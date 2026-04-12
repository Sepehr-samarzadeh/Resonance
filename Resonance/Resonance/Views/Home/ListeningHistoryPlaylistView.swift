//  ListeningHistoryPlaylistView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - ListeningHistoryPlaylistView

/// A full playlist-style view of the user's listening history.
/// Songs are shown in a list with artwork, title, artist, and a play button.
struct ListeningHistoryPlaylistView: View {

    // MARK: - Properties

    let songs: [Song]
    let playerViewModel: PlayerViewModel

    // MARK: - Body

    var body: some View {
        List {
            if songs.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Listening History"),
                    systemImage: "music.note.list",
                    description: Text(String(localized: "Start listening to music to build your playlist."))
                )
            } else {
                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    let isNowPlaying = playerViewModel.currentSong?.id == song.id

                    Button {
                        Task { await playerViewModel.play(song: song, in: songs) }
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundStyle(isNowPlaying ? AnyShapeStyle(.musicRed) : AnyShapeStyle(.secondary))
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
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(String(localized: "Listening History"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
