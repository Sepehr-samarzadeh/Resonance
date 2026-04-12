//  HomeListeningHistoryCard.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - HomeListeningHistoryCard

/// A playlist-style card that represents the user's listening history.
/// Shows a 2x2 mosaic of recent artwork and taps into the full playlist view.
struct HomeListeningHistoryCard: View {

    // MARK: - Properties

    let songs: [Song]
    let playerViewModel: PlayerViewModel

    /// Songs deduplicated by catalog ID.
    private var uniqueSongs: [Song] {
        var seen = Set<MusicItemID>()
        return songs.filter { seen.insert($0.id).inserted }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Your Listening History"), systemImage: "music.note.list")
                .font(.headline)

            NavigationLink {
                ListeningHistoryPlaylistView(
                    songs: uniqueSongs,
                    playerViewModel: playerViewModel
                )
            } label: {
                HStack(spacing: 14) {
                    artworkMosaic
                        .frame(width: 80, height: 80)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Recently Played"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        Text(String(localized: "\(uniqueSongs.count) songs"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption2)
                            Text(String(localized: "View All"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.musicRed)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "View listening history playlist, \(uniqueSongs.count) songs"))
        }
    }

    // MARK: - Artwork Mosaic

    /// A 2x2 grid of album artworks from recent songs, or a fallback icon.
    private var artworkMosaic: some View {
        let artworkSongs = Array(uniqueSongs.prefix(4))

        return Group {
            if artworkSongs.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.musicRed.opacity(0.2))
                    .overlay {
                        Image(systemName: "music.note.list")
                            .font(.title2)
                            .foregroundStyle(.musicRed)
                    }
            } else {
                let columns = [
                    GridItem(.flexible(), spacing: 2),
                    GridItem(.flexible(), spacing: 2)
                ]
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<4, id: \.self) { index in
                        if index < artworkSongs.count,
                           let artwork = artworkSongs[index].artwork {
                            ArtworkImage(artwork, width: 39)
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(.musicRed.opacity(0.15))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
