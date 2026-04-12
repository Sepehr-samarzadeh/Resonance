//  AlbumArtGrid.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - AlbumArtGrid

/// An iPod-style grid of album artwork tiles for recently played songs.
struct AlbumArtGrid: View {

    // MARK: - Properties

    let songs: [Song]
    let playerViewModel: PlayerViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // MARK: - Body

    /// Songs deduplicated by catalog ID so `ForEach` never sees
    /// the same `MusicItemID` twice (recently played can contain repeats).
    private var uniqueSongs: [Song] {
        var seen = Set<MusicItemID>()
        return songs.filter { seen.insert($0.id).inserted }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recently Played"))
                .font(.headline)

            if songs.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Recent Songs"),
                    systemImage: "music.note",
                    description: Text(String(localized: "Start listening to see your recent tracks here."))
                )
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(uniqueSongs) { song in
                        AlbumArtTile(song: song) {
                            playSong(song)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func playSong(_ song: Song) {
        Task { await playerViewModel.play(song: song, in: uniqueSongs) }
    }
}
