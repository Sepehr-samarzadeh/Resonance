//  MusicChartView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - MusicChartView

struct MusicChartView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: MusicChartViewModel?

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                chartContent(viewModel: viewModel)
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

    // MARK: - Chart Content

    @ViewBuilder
    private func chartContent(viewModel: MusicChartViewModel) -> some View {
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
