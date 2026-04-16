//  OnRepeatCardStack.swift
//  Resonance

import SwiftUI

// MARK: - OnRepeatCardStack

/// A fanned-out stack of album art cards representing the user's most-played songs.
/// Cards are offset and rotated, with the top card being the #1 most played.
struct OnRepeatCardStack: View {

    // MARK: - Properties

    let songs: [OnRepeatSong]

    @State private var selectedIndex: Int?

    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 180

    // MARK: - Body

    var body: some View {
        ZStack {
            ForEach(Array(songs.enumerated().reversed()), id: \.element.id) { index, song in
                OnRepeatCard(
                    song: song,
                    rank: index + 1,
                    isSelected: selectedIndex == index
                )
                .frame(width: cardWidth, height: cardHeight)
                .offset(x: xOffset(for: index))
                .rotationEffect(rotation(for: index), anchor: .bottom)
                .zIndex(zIndex(for: index))
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.35)) {
                        selectedIndex = selectedIndex == index ? nil : index
                    }
                }
            }
        }
        .frame(height: cardHeight + 40)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Your top \(songs.count) songs on repeat"))
    }

    // MARK: - Layout Helpers

    private func xOffset(for index: Int) -> CGFloat {
        let center = Double(songs.count - 1) / 2.0
        let base = (Double(index) - center) * 32
        if selectedIndex == index {
            return base
        }
        return base
    }

    private func rotation(for index: Int) -> Angle {
        let center = Double(songs.count - 1) / 2.0
        let base = (Double(index) - center) * 6
        if selectedIndex == index {
            return .zero
        }
        return .degrees(base)
    }

    private func zIndex(for index: Int) -> Double {
        if selectedIndex == index {
            return 100
        }
        return Double(songs.count - index)
    }
}

// MARK: - OnRepeatCard

/// A single card in the stack showing album artwork, song name, and play count.
struct OnRepeatCard: View {

    let song: OnRepeatSong
    let rank: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Album artwork
            artworkView
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .clipped()

            // Info bar
            VStack(spacing: 2) {
                Text(song.songName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(.white.opacity(0.15), lineWidth: 1)
        }
        .overlay(alignment: .topLeading) {
            rankBadge
        }
        .overlay(alignment: .topTrailing) {
            playCountBadge
        }
        .shadow(color: .black.opacity(0.18), radius: isSelected ? 12 : 6, y: isSelected ? 8 : 3)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "\(song.songName) by \(song.artistName), played \(song.playCount) times, rank \(rank)"))
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let urlString = song.artworkURL, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                artworkPlaceholder
            }
        } else {
            artworkPlaceholder
        }
    }

    private var artworkPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [.musicRed.opacity(0.6), .indigo.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .font(.title)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Badges

    private var rankBadge: some View {
        Text("#\(rank)")
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.musicRed, in: Capsule())
            .padding(6)
    }

    private var playCountBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "play.fill")
                .font(.system(size: 7))
            Text("\(song.playCount)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.5), in: Capsule())
        .padding(6)
    }
}
