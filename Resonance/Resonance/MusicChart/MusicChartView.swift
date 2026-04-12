//  MusicChartView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - MusicChartView

struct MusicChartView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: MusicChartViewModel?
    let playerViewModel: PlayerViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                ChartContentView(viewModel: viewModel, playerViewModel: playerViewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Top Charts"))
        .task {
            if viewModel == nil {
                viewModel = MusicChartViewModel(musicService: services.musicService)
            }
            await viewModel?.fetchCharts()
        }
        .refreshable {
            await viewModel?.fetchCharts()
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - ChartContentView

/// Chart content with skeleton loading and empty state.
private struct ChartContentView: View {
    let viewModel: MusicChartViewModel
    let playerViewModel: PlayerViewModel

    private var hasChartSongs: Bool {
        viewModel.songCharts.contains { !$0.items.isEmpty }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonSongRow()
                    }
                } else if !hasChartSongs {
                    ContentUnavailableView(
                        String(localized: "No Charts Available"),
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text(String(localized: "Charts couldn't be loaded right now. Pull to refresh."))
                    )
                } else {
                    ForEach(viewModel.songCharts) { songChart in
                        let chartSongs = Array(songChart.items)
                        ForEach(chartSongs) { song in
                            ChartSongRow(
                                song: song,
                                allSongs: chartSongs,
                                playerViewModel: playerViewModel
                            )
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - ChartSongRow

/// A tappable row in the charts list that plays the song on tap.
struct ChartSongRow: View {
    let song: Song
    let allSongs: [Song]
    let playerViewModel: PlayerViewModel

    private var isNowPlaying: Bool {
        playerViewModel.currentSong?.id == song.id
    }

    var body: some View {
        Button {
            Task { await playerViewModel.play(song: song, in: allSongs) }
        } label: {
            HStack(spacing: 12) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.body)
                        .fontWeight(.semibold)
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
                        .font(.title3)
                        .foregroundStyle(.musicRed)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                        .accessibilityLabel(String(localized: "Now Playing"))
                } else {
                    Image(systemName: "play.circle")
                        .font(.title3)
                        .foregroundStyle(.musicRed)
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: isNowPlaying ? "Now playing: \(song.title) by \(song.artistName)" : "Play \(song.title) by \(song.artistName)"))
        .sensoryFeedback(.impact(flexibility: .soft), trigger: playerViewModel.currentSong?.id)
    }
}
