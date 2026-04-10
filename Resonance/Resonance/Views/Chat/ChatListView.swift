//  ChatListView.swift
//  Resonance

import SwiftUI

// MARK: - ChatListView

struct ChatListView: View {

    // MARK: - Properties

    @State private var viewModel = MatchViewModel()
    let currentUserId: String

    // MARK: - Body

    var body: some View {
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
        .navigationTitle(String(localized: "Messages"))
        .task {
            await viewModel.listenForMatches(userId: currentUserId)
        }
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

    @State private var otherUser: ResonanceUser?
    private let userService = UserService()

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
            otherUser = try? await userService.fetchUser(userId: otherUserId)
        }
    }
}
