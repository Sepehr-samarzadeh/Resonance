//  ProfileStatsSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileStatsSection

struct ProfileStatsSection: View {

    // MARK: - Properties

    let user: ResonanceUser?
    let sessionCount: Int

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            statItem(
                value: "\(user?.topArtists.count ?? 0)",
                title: String(localized: "Artists"),
                icon: "music.mic"
            )

            Divider()
                .frame(height: 32)

            statItem(
                value: "\(user?.favoriteGenres.count ?? 0)",
                title: String(localized: "Genres"),
                icon: "guitars"
            )

            Divider()
                .frame(height: 32)

            statItem(
                value: "\(sessionCount)",
                title: String(localized: "Sessions"),
                icon: "headphones"
            )
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stat Item

    private func statItem(value: String, title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.musicRed)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .contentTransition(.numericText())

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
