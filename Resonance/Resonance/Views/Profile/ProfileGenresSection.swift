//  ProfileGenresSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileGenresSection

struct ProfileGenresSection: View {

    // MARK: - Properties

    let genres: [String]

    // MARK: - Private

    private let genreColors: [Color] = [
        .purple, .pink, .indigo, .blue, .teal, .mint, .orange
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Favorite Genres"), systemImage: "guitars")
                .font(.headline)

            if genres.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Genres"), systemImage: "guitars")
                } description: {
                    Text(String(localized: "Add your favorite genres in Edit Profile."))
                }
                .frame(height: 100)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(Array(genres.enumerated()), id: \.element) { index, genre in
                        GenreChip(
                            genre: genre,
                            color: genreColors[index % genreColors.count]
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - GenreChip

struct GenreChip: View {

    let genre: String
    let color: Color

    var body: some View {
        Text(genre)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
