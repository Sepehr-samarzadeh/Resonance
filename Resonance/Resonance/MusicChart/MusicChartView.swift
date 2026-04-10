//  MusicChartView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - MusicChartView

struct MusicChartView: View {

    // MARK: - Properties

    @State private var viewModel = MusicChartViewModel()

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                ForEach(viewModel.songCharts) { songChart in
                    ForEach(songChart.items) { song in
                        songRow(song)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "Top Charts"))
        .task {
            await viewModel.fetchCharts()
        }
    }

    // MARK: - Song Row

    @ViewBuilder
    private func songRow(_ song: Song) -> some View {
        HStack(spacing: 12) {
            if let artwork = song.artwork {
                ArtworkImage(artwork, width: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(song.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
