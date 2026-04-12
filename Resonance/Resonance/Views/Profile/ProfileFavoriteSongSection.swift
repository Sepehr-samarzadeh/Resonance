//  ProfileFavoriteSongSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileFavoriteSongSection

struct ProfileFavoriteSongSection: View {

    // MARK: - Properties

    let song: FavoriteSong

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Favorite Song"), systemImage: "heart.fill")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 14) {
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.musicRed, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusSmall))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
