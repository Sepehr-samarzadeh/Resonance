//  ProfileListeningHistorySection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileListeningHistorySection

struct ProfileListeningHistorySection: View {

    // MARK: - Properties

    let sessions: [ListeningSession]
    @State private var showAllSessions = false

    private let previewLimit = 5

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(String(localized: "Recent Listening"), systemImage: "clock.arrow.circlepath")
                    .font(.headline)

                Spacer()

                if sessions.count > previewLimit {
                    Button(showAllSessions
                           ? String(localized: "Show Less")
                           : String(localized: "See All (\(sessions.count))")) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllSessions.toggle()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.purple)
                }
            }

            if sessions.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Listening History"), systemImage: "headphones")
                } description: {
                    Text(String(localized: "Start listening to music to build your history."))
                }
                .frame(height: 120)
            } else {
                let displayedSessions = showAllSessions ? sessions : Array(sessions.prefix(previewLimit))

                VStack(spacing: 0) {
                    ForEach(Array(displayedSessions.enumerated()), id: \.element.id) { index, session in
                        ListeningHistoryRow(session: session)

                        if index < displayedSessions.count - 1 {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - ListeningHistoryRow

struct ListeningHistoryRow: View {

    let session: ListeningSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .indigo.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.songName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(session.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.listenedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if session.durationSeconds > 0 {
                    Text(formattedDuration)
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var formattedDuration: String {
        let minutes = session.durationSeconds / 60
        let seconds = session.durationSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
