//  MiniPlayerView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - MiniPlayerView

struct MiniPlayerView: View {

    // MARK: - Properties

    @State private var viewModel: PlayerViewModel

    init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        if let song = viewModel.currentSong {
            HStack(spacing: 10) {
                if let artwork = song.artwork {
                    ArtworkImage(artwork, width: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.footnote)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(song.artistName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    Task { await viewModel.togglePlayback() }
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.body)
                }
                .accessibilityLabel(viewModel.isPlaying ? String(localized: "Pause") : String(localized: "Play"))
                .buttonStyle(.plain)

                Button {
                    Task { await viewModel.skipToNext() }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.caption)
                }
                .accessibilityLabel(String(localized: "Next track"))
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
}
