//  MatchFeedView.swift
//  Resonance

import SwiftUI

// MARK: - MatchFeedView

struct MatchFeedView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State var viewModel: MatchViewModel
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        matchContent(viewModel: viewModel)
            .navigationTitle(String(localized: "Matches"))
            .task {
                await viewModel.listenForMatches(userId: currentUserId)
            }
            .alert(
                String(localized: "Error"),
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

    // MARK: - Match Content

    @ViewBuilder
    private func matchContent(viewModel: MatchViewModel) -> some View {
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
                        .onAppear {
                            if match.id == viewModel.matches.last?.id {
                                Task {
                                    await viewModel.loadMoreMatches(userId: currentUserId)
                                }
                            }
                        }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding()
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - MatchCardView

struct MatchCardView: View {
    let match: Match
    let currentUserId: String

    @Environment(\.services) private var services
    @State private var otherUser: ResonanceUser?

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.purple.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: match.matchType == .realtime ? "waveform" : "clock")
                        .foregroundStyle(.purple)
                }
                .accessibilityHidden(true)

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
            do {
                otherUser = try await services.userService.fetchUser(userId: otherUserId)
            } catch {
                print("MatchCardView: Failed to load other user — \(error.localizedDescription)")
            }
        }
    }
}
