//  ChatListView.swift
//  Resonance

import SwiftUI

// MARK: - ChatListView

struct ChatListView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: MatchViewModel?
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                chatListContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Messages"))
        .task {
            if viewModel == nil {
                viewModel = MatchViewModel(
                    matchService: services.matchService,
                    userService: services.userService
                )
            }
            await viewModel?.listenForMatches(userId: currentUserId)
        }
    }

    // MARK: - Chat List Content

    @ViewBuilder
    private func chatListContent(viewModel: MatchViewModel) -> some View {
        List {
            if viewModel.matches.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    String(localized: "No Conversations"),
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text(String(localized: "Match with someone to start chatting."))
                )
            } else {
                ForEach(viewModel.matches) { match in
                    NavigationLink(value: match) {
                        ChatRowView(match: match, currentUserId: currentUserId)
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - ChatRowView

struct ChatRowView: View {
    let match: Match
    let currentUserId: String

    @Environment(\.services) private var services
    @State private var otherUser: ResonanceUser?

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.purple.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.purple)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(otherUser?.displayName ?? String(localized: "Loading..."))
                    .font(.headline)

                if let song = match.triggerSong {
                    Text(String(localized: "Matched on \(song.name)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(match.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .task {
            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else { return }
            do {
                otherUser = try await services.userService.fetchUser(userId: otherUserId)
            } catch {
                print("ChatRowView: Failed to load other user — \(error.localizedDescription)")
            }
        }
    }
}
