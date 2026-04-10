//  MatchFeedView.swift
//  Resonance

import SwiftUI

// MARK: - MatchFeedView

struct MatchFeedView: View {

    // MARK: - Properties

    @State private var viewModel = MatchViewModel()
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }

                if viewModel.matches.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        String(localized: "No Matches Yet"),
                        systemImage: "person.2.slash",
                        description: Text(String(localized: "Start listening to music and we'll find people who share your taste."))
                    )
                } else {
                    ForEach(viewModel.matches) { match in
                        NavigationLink(value: match) {
                            MatchCardView(match: match, currentUserId: currentUserId)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "Matches"))
        .task {
            await viewModel.listenForMatches(userId: currentUserId)
        }
    }
}

// MARK: - MatchCardView

struct MatchCardView: View {
    let match: Match
    let currentUserId: String

    @State private var otherUser: ResonanceUser?
    private let userService = UserService()

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.purple.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: match.matchType == .realtime ? "waveform" : "clock")
                        .foregroundStyle(.purple)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.displayName ?? String(localized: "Loading..."))
                    .font(.headline)

                if let song = match.triggerSong {
                    Text(String(localized: "Matched on: \(song.name)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let score = match.similarityScore {
                    Text(String(localized: "Similarity: \(Int(score * 100))%"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            MatchScoreBadge(score: match.similarityScore)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .task {
            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else { return }
            otherUser = try? await userService.fetchUser(userId: otherUserId)
        }
    }
}
