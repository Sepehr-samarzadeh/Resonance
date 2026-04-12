//  HomeFeaturedArtistsSection.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - HomeFeaturedArtistsSection

/// Horizontal scroll of featured artist photos extracted from the user's
/// recently played songs. Each artist is shown with their photo and name.
struct HomeFeaturedArtistsSection: View {

    // MARK: - Properties

    let artists: [FeaturedArtist]

    // MARK: - Body

    var body: some View {
        if !artists.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "Your Artists"), systemImage: "music.mic")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(artists) { artist in
                            featuredArtistTile(artist)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Artist Tile

    private func featuredArtistTile(_ artist: FeaturedArtist) -> some View {
        VStack(spacing: 8) {
            if let artwork = artist.artwork {
                ArtworkImage(artwork, width: 90)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.musicRed.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .overlay {
                        Image(systemName: "music.mic")
                            .font(.title2)
                            .foregroundStyle(.musicRed)
                    }
            }

            Text(artist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(artist.name)
    }
}

// MARK: - FeaturedArtist

/// Lightweight model for a featured artist displayed on the Home tab.
struct FeaturedArtist: Identifiable, Sendable {
    let id: String
    let name: String
    let artwork: Artwork?
}
