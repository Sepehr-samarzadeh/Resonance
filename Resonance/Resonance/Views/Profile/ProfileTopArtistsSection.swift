//  ProfileTopArtistsSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileTopArtistsSection

struct ProfileTopArtistsSection: View {

    // MARK: - Properties

    let artists: [TopArtist]
    let onAutoPopulate: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(String(localized: "Top Artists"), systemImage: "star.fill")
                    .font(.headline)

                Spacer()

                Button(String(localized: "Auto-populate"), systemImage: "arrow.trianglehead.2.clockwise") {
                    onAutoPopulate()
                }
                .font(.caption)
                .foregroundStyle(.purple)
            }

            if artists.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Top Artists"), systemImage: "music.mic")
                } description: {
                    Text(String(localized: "Tap auto-populate to import artists from your listening history."))
                }
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(artists.enumerated()), id: \.element.id) { index, artist in
                            ArtistCard(artist: artist, rank: index + 1)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
