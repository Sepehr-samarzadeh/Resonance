//  AlbumArtTile.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - AlbumArtTile

/// A single album artwork tile for the iPod-style grid.
/// Shows the artwork image with song title and artist name below.
struct AlbumArtTile: View {

    // MARK: - Properties

    let song: Song
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                artwork
                songInfo
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title), \(song.artistName)")
        .accessibilityHint(String(localized: "Double tap to play"))
    }

    // MARK: - Subviews

    @ViewBuilder
    private var artwork: some View {
        if let artwork = song.artwork {
            ArtworkImage(artwork, width: 180)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
        } else {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.title)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
        }
    }

    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            Text(song.artistName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
