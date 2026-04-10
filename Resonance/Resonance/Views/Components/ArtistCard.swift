//  ArtistCard.swift
//  Resonance

import SwiftUI

// MARK: - ArtistCard

struct ArtistCard: View {

    // MARK: - Properties

    let artist: TopArtist

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(.purple.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay {
                    Image(systemName: "music.mic")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }

            Text(artist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(width: 80)
        }
    }
}
