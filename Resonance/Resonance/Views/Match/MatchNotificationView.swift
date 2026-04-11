//  MatchNotificationView.swift
//  Resonance

import SwiftUI

// MARK: - MatchNotificationView

struct MatchNotificationView: View {

    // MARK: - Properties

    let match: Match
    let otherUserName: String
    var onDismiss: () -> Void
    var onViewMatch: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 60

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(.purple)
                .symbolEffect(.bounce, isActive: !reduceMotion)
                .accessibilityHidden(true)

            Text(String(localized: "New Match!"))
                .font(.title)
                .fontWeight(.bold)

            Text(String(localized: "You and \(otherUserName) share similar music taste!"))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let song = match.triggerSong {
                Label(String(localized: "\(song.name) by \(song.artistName)"), systemImage: "music.note")
                    .font(.subheadline)
                    .foregroundStyle(.purple)
            }

            HStack(spacing: 16) {
                Button(String(localized: "Later"), role: .cancel) {
                    onDismiss()
                }
                .buttonStyle(.bordered)

                Button(String(localized: "View Match")) {
                    onViewMatch()
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 20)
        .padding(.horizontal, 32)
    }
}
