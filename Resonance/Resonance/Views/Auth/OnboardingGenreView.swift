//  OnboardingGenreView.swift
//  Resonance

import SwiftUI

// MARK: - OnboardingGenreView

/// Onboarding step where users pick their favorite music genres.
/// Requires at least 3 selections before proceeding.
struct OnboardingGenreView: View {

    // MARK: - Properties

    @Binding var selectedGenres: Set<String>
    var onNext: () -> Void

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 60

    // MARK: - Constants

    private static let allGenres: [String] = [
        "Pop", "Rock", "Hip-Hop", "R&B", "Jazz", "Classical",
        "Electronic", "Country", "Latin", "Metal", "Indie",
        "Alternative", "Soul", "Funk", "Reggae", "Blues",
        "Folk", "Punk", "K-Pop", "J-Pop", "Afrobeats",
        "Dance", "Lo-Fi", "Ambient", "Gospel", "Soundtrack"
    ]

    private static let genreEmojis: [String: String] = [
        "Pop": "🎤", "Rock": "🎸", "Hip-Hop": "🎙️", "R&B": "🎵",
        "Jazz": "🎷", "Classical": "🎻", "Electronic": "🎛️", "Country": "🤠",
        "Latin": "💃", "Metal": "🤘", "Indie": "🎹", "Alternative": "🔊",
        "Soul": "❤️", "Funk": "🕺", "Reggae": "🌴", "Blues": "🎺",
        "Folk": "🪕", "Punk": "⚡", "K-Pop": "🇰🇷", "J-Pop": "🇯🇵",
        "Afrobeats": "🥁", "Dance": "🪩", "Lo-Fi": "☕", "Ambient": "🌊",
        "Gospel": "🙏", "Soundtrack": "🎬"
    ]

    private var canProceed: Bool {
        selectedGenres.count >= 3
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "guitars.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.musicRed)
                .accessibilityHidden(true)

            Text(String(localized: "Pick Your Genres"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Select at least 3 genres you love."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            genreGrid
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 8) {
                if !selectedGenres.isEmpty {
                    Text(String(localized: "\(selectedGenres.count) selected"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    onNext()
                } label: {
                    Text(String(localized: "Next"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canProceed ? .musicRed : .gray.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canProceed)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .padding()
        .animation(.easeOut(duration: 0.2), value: selectedGenres)
    }

    // MARK: - Genre Grid

    private var genreGrid: some View {
        ScrollView {
            FlowLayout(spacing: 10) {
                ForEach(Self.allGenres, id: \.self) { genre in
                    genreButton(genre)
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxHeight: 300)
    }

    // MARK: - Genre Button

    private func genreButton(_ genre: String) -> some View {
        let isSelected = selectedGenres.contains(genre)
        let emoji = Self.genreEmojis[genre] ?? "🎵"

        return Button {
            if isSelected {
                selectedGenres.remove(genre)
            } else {
                selectedGenres.insert(genre)
            }
        } label: {
            HStack(spacing: 6) {
                Text(emoji)
                    .font(.callout)
                Text(genre)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? .musicRed.opacity(0.2) : .white.opacity(0.08))
            .foregroundStyle(isSelected ? .musicRed : .white.opacity(0.8))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? .musicRed : .clear, lineWidth: 1.5)
            )
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(genre)
    }
}
