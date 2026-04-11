//  NowPlayingBar.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - NowPlayingBar

struct NowPlayingBar: View {

    // MARK: - Properties

    @State private var playerViewModel: PlayerViewModel
    var onTap: () -> Void

    init(playerViewModel: PlayerViewModel, onTap: @escaping () -> Void) {
        _playerViewModel = State(initialValue: playerViewModel)
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        if let song = playerViewModel.currentSong {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    if let artwork = song.artwork {
                        ArtworkImage(artwork, width: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(song.title)
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(song.artistName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        Task {
                            await playerViewModel.togglePlayback()
                        }
                    } label: {
                        Image(systemName: playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(playerViewModel.isPlaying ? String(localized: "Pause") : String(localized: "Play"))
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .accessibilityElement(children: .contain)
            .accessibilityHint(String(localized: "Opens the full player"))
        }
    }
}
