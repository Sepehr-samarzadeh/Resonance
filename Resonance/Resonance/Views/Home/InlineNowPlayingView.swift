//  InlineNowPlayingView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - InlineNowPlayingView

/// Displays the currently playing song inline within the Home tab,
/// with large artwork, song info, and playback controls.
struct InlineNowPlayingView: View {

    // MARK: - Properties

    let playerViewModel: PlayerViewModel
    @ScaledMetric(relativeTo: .largeTitle) private var playPauseSize: CGFloat = 52
    @ScaledMetric(relativeTo: .title) private var placeholderIconSize: CGFloat = 48

    // MARK: - Body

    var body: some View {
        if let song = playerViewModel.currentSong {
            VStack(spacing: 16) {
                InlineArtworkView(
                    song: song,
                    placeholderIconSize: placeholderIconSize
                )

                InlineSongInfoView(song: song)

                PlaybackProgressBar(
                    playbackTime: playerViewModel.playbackTime,
                    duration: playerViewModel.songDuration,
                    onSeek: { time in await playerViewModel.seek(to: time) }
                )
                .padding(.horizontal, 20)

                InlinePlaybackControls(
                    playerViewModel: playerViewModel,
                    playPauseSize: playPauseSize
                )
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Now Playing"))
        }
    }
}

// MARK: - InlineArtworkView

/// Large artwork display for the inline now-playing section.
private struct InlineArtworkView: View {
    let song: Song
    let placeholderIconSize: CGFloat

    var body: some View {
        if let artwork = song.artwork {
            ArtworkImage(artwork, width: Constants.UI.artworkLargeSize)
                .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge))
                .shadow(color: .musicRed.opacity(0.3), radius: 16, y: 8)
                .transition(.scale.combined(with: .opacity))
        } else {
            RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
                .frame(
                    width: Constants.UI.artworkLargeSize,
                    height: Constants.UI.artworkLargeSize
                )
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: placeholderIconSize))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
        }
    }
}

// MARK: - InlineSongInfoView

/// Song title and artist name for the inline now-playing section.
private struct InlineSongInfoView: View {
    let song: Song

    var body: some View {
        VStack(spacing: 4) {
            Text(song.title)
                .font(.title3)
                .fontWeight(.bold)
                .lineLimit(1)

            Text(song.artistName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - InlinePlaybackControls

/// Playback controls (previous, play/pause, next) for the inline player.
private struct InlinePlaybackControls: View {
    let playerViewModel: PlayerViewModel
    let playPauseSize: CGFloat

    var body: some View {
        HStack(spacing: 40) {
            Button("Previous track", systemImage: "backward.fill", action: skipToPrevious)
                .font(.title2)
                .labelStyle(.iconOnly)

            Button(
                playerViewModel.isPlaying
                    ? String(localized: "Pause")
                    : String(localized: "Play"),
                systemImage: playerViewModel.isPlaying
                    ? "pause.circle.fill"
                    : "play.circle.fill",
                action: togglePlayback
            )
            .font(.system(size: playPauseSize))
            .labelStyle(.iconOnly)

            Button("Next track", systemImage: "forward.fill", action: skipToNext)
                .font(.title2)
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func togglePlayback() {
        Task { await playerViewModel.togglePlayback() }
    }

    private func skipToPrevious() {
        Task { await playerViewModel.skipToPrevious() }
    }

    private func skipToNext() {
        Task { await playerViewModel.skipToNext() }
    }
}
