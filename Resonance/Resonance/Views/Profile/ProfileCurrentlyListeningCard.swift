//  ProfileCurrentlyListeningCard.swift
//  Resonance

import SwiftUI

// MARK: - ProfileCurrentlyListeningCard

/// Displays what the user is currently listening to with an animated waveform indicator.
struct ProfileCurrentlyListeningCard: View {

    // MARK: - Properties

    let currentlyListening: CurrentlyListening

    // MARK: - Private

    private var artworkURL: URL? {
        guard let urlString = currentlyListening.artworkURL else { return nil }
        return URL(string: urlString)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 14) {
            // Song artwork or fallback icon
            CachedAsyncImage(url: artworkURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusSmall))
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusSmall))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    AudioWaveformView()
                        .frame(width: 16, height: 12)

                    Text(String(localized: "Now Playing"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                        .textCase(.uppercase)
                }

                if let songName = currentlyListening.songName {
                    Text(songName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                if let artistName = currentlyListening.artistName {
                    Text(artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.purple.opacity(0.3), lineWidth: 1)
        }
    }
}

// MARK: - AudioWaveformView

/// Animated waveform bars that indicate active playback.
struct AudioWaveformView: View {

    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    private let barCount = 3
    private let barWidth: CGFloat = 2.5

    // MARK: - Body

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(.purple)
                    .frame(width: barWidth)
                    .scaleEffect(
                        y: isAnimating ? CGFloat.random(in: 0.3...1.0) : 0.4,
                        anchor: .bottom
                    )
            }
        }
        .task {
            guard !reduceMotion else { return }
            // Continuously animate the bars
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isAnimating.toggle()
                }
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
        .accessibilityHidden(true)
    }
}
