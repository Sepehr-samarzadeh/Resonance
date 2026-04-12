//  HomeTopChartsSection.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - HomeTopChartsSection

/// A compact preview of the top music charts on the Home tab.
/// Tapping "See All" navigates to the full `MusicChartView`.
struct HomeTopChartsSection: View {

    // MARK: - Properties

    let songs: [Song]
    let playerViewModel: PlayerViewModel
    private let previewLimit = 4

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(String(localized: "Top Charts"), systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                Spacer()

                NavigationLink {
                    MusicChartView(playerViewModel: playerViewModel)
                } label: {
                    Text(String(localized: "See All"))
                        .font(.caption)
                        .foregroundStyle(.musicRed)
                }
            }

            if songs.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .frame(height: 80)
                    .overlay {
                        ProgressView()
                    }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(songs.prefix(previewLimit).enumerated()), id: \.element.id) { index, song in
                        chartRow(song: song, rank: index + 1)

                        if index < min(previewLimit, songs.count) - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Chart Row

    private func chartRow(song: Song, rank: Int) -> some View {
        let isNowPlaying = playerViewModel.currentSong?.id == song.id

        return Button {
            Task { await playerViewModel.play(song: song, in: songs) }
        } label: {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.musicRed)
                    .frame(width: 24)

                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.musicRed.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "music.note")
                                .font(.caption)
                                .foregroundStyle(.musicRed)
                        }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(isNowPlaying ? AnyShapeStyle(.musicRed) : AnyShapeStyle(.primary))
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isNowPlaying && playerViewModel.isPlaying {
                    Image(systemName: "waveform")
                        .font(.body)
                        .foregroundStyle(.musicRed)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                        .accessibilityLabel(String(localized: "Now Playing"))
                } else {
                    Image(systemName: "play.circle")
                        .font(.body)
                        .foregroundStyle(.musicRed)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: isNowPlaying ? "Now playing: \(song.title) by \(song.artistName)" : "Play \(song.title) by \(song.artistName)"))
    }
}
