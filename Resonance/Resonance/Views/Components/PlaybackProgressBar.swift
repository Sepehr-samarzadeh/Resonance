//  PlaybackProgressBar.swift
//  Resonance

import SwiftUI

// MARK: - PlaybackProgressBar

/// A scrubber that shows elapsed / remaining time and allows seeking.
struct PlaybackProgressBar: View {

    // MARK: - Properties

    let playbackTime: TimeInterval
    let duration: TimeInterval?
    let onSeek: (TimeInterval) async -> Void

    @State private var isDragging = false
    @State private var dragValue: Double = 0

    // MARK: - Body

    var body: some View {
        if let duration, duration > 0 {
            VStack(spacing: 4) {
                Slider(
                    value: isDragging
                        ? $dragValue
                        : .init(
                            get: { playbackTime / duration },
                            set: { dragValue = $0 }
                        ),
                    in: 0...1
                ) { editing in
                    isDragging = editing
                    if !editing {
                        let seekTime = dragValue * duration
                        Task { await onSeek(seekTime) }
                    }
                }
                .tint(.musicRed)

                HStack {
                    Text(formatTime(isDragging ? dragValue * duration : playbackTime))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    Spacer()

                    Text("-\(formatTime(duration - (isDragging ? dragValue * duration : playbackTime)))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "Playback progress"))
            .accessibilityValue(String(localized: "\(formatTime(playbackTime)) of \(formatTime(duration))"))
        }
    }

    // MARK: - Helpers

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = max(0, Int(time))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
