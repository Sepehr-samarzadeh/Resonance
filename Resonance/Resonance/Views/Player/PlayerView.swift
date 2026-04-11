//  PlayerView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - PlayerView

struct PlayerView: View {

    // MARK: - Properties

    @State private var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .largeTitle) private var playPauseSize: CGFloat = 64
    @ScaledMetric(relativeTo: .title) private var artworkPlaceholderIconSize: CGFloat = 60

    init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            dismissHandle

            Spacer()

            artworkSection

            songInfoSection

            playbackControls

            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.purple.opacity(0.3), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .alert(
            String(localized: "Playback Error"),
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Dismiss Handle

    private var dismissHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.secondary)
            .frame(width: 40, height: 5)
            .padding(.top, 8)
            .accessibilityHidden(true)
    }

    // MARK: - Artwork Section

    @ViewBuilder
    private var artworkSection: some View {
        if let song = viewModel.currentSong, let artwork = song.artwork {
            ArtworkImage(artwork, width: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .purple.opacity(0.3), radius: 20, y: 10)
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .frame(width: 300, height: 300)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: artworkPlaceholderIconSize))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
        }
    }

    // MARK: - Song Info Section

    private var songInfoSection: some View {
        VStack(spacing: 8) {
            Text(viewModel.currentSong?.title ?? String(localized: "Not Playing"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(viewModel.currentSong?.artistName ?? "")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button {
                Task { await viewModel.skipToPrevious() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(String(localized: "Previous track"))

            Button {
                Task { await viewModel.togglePlayback() }
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: playPauseSize))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(viewModel.isPlaying ? String(localized: "Pause") : String(localized: "Play"))

            Button {
                Task { await viewModel.skipToNext() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            .accessibilityLabel(String(localized: "Next track"))
        }
    }
}
