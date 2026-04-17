//  MatchFeedView.swift
//  Resonance

import SwiftUI
import OSLog

// MARK: - MatchFeedView

struct MatchFeedView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State var viewModel: MatchViewModel
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        MatchFeedContent(viewModel: viewModel, currentUserId: currentUserId)
            .navigationTitle(String(localized: "Matches"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.listenForMatches(userId: currentUserId)
            }
            .refreshable {
                await viewModel.loadMatches(userId: currentUserId)
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
}

// MARK: - MatchFeedContent

/// The scrollable match feed content, extracted to scope observation.
struct MatchFeedContent: View {
    let viewModel: MatchViewModel
    let currentUserId: String

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonMatchCard()
                    }
                }

                if viewModel.matches.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        String(localized: "No Matches Yet"),
                        systemImage: "person.2.slash",
                        description: Text(String(localized: "Start listening to music and we'll find people who share your taste."))
                    )
                    .containerRelativeFrame(.vertical)
                } else {
                    ForEach(Array(viewModel.matches.enumerated()), id: \.element.id) { index, match in
                        NavigationLink(value: match) {
                            MatchCardView(match: match, currentUserId: currentUserId)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
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
            .animation(.easeInOut(duration: 0.3), value: viewModel.matches.count)
        }
    }
}

// MARK: - MatchCardView

struct MatchCardView: View {
    let match: Match
    let currentUserId: String

    @Environment(\.services) private var services
    @State private var otherUser: ResonanceUser?
    @State private var didLoadUser = false

    var body: some View {
        HStack(spacing: 14) {
            ProfilePhotoView(
                photoURL: otherUser?.photoURL,
                size: 50,
                fallbackIcon: match.matchType == .realtime ? "waveform" : "clock"
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.displayName ?? (didLoadUser ? String(localized: "Resonance User") : String(localized: "Loading...")))
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
            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else {
                didLoadUser = true
                return
            }
            do {
                otherUser = try await services.userService.fetchUser(userId: otherUserId)
            } catch {
                Log.ui.error("Failed to load other user: \(error.localizedDescription)")
            }
            didLoadUser = true
        }
    }
}
