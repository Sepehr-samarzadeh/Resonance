//  ArtistCard.swift
//  Resonance

import SwiftUI

// MARK: - ArtistCard

struct ArtistCard: View {

    // MARK: - Properties

    let artist: TopArtist
    var rank: Int?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                artistImage

                if let rank {
                    Text("#\(rank)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.musicRed)
                        .clipShape(Capsule())
                        .offset(x: 4, y: -4)
                }
            }

            Text(artist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rank != nil
            ? String(localized: "Number \(rank!) artist, \(artist.name)")
            : artist.name
        )
    }

    // MARK: - Artist Image

    private var artistImage: some View {
        Group {
            if let urlString = artist.artworkURL,
               let url = URL(string: urlString) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } placeholder: {
                    artistPlaceholder
                }
            } else {
                artistPlaceholder
            }
        }
    }

    private var artistPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.musicRed.opacity(0.25), .indigo.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 72, height: 72)
            .overlay {
                Image(systemName: "music.mic")
                    .font(.title2)
                    .foregroundStyle(.musicRed)
                    .accessibilityHidden(true)
            }
    }
}
