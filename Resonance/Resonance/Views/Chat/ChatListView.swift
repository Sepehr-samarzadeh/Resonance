//  ChatListView.swift
//  Resonance

import SwiftUI
import OSLog

// MARK: - ChatListView

struct ChatListView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State var viewModel: MatchViewModel
    let currentUserId: String

    // MARK: - Body

    var body: some View {
        ChatListContent(viewModel: viewModel, currentUserId: currentUserId)
            .navigationTitle(String(localized: "Messages"))
            .task(id: currentUserId) {
                if viewModel.matches.isEmpty {
                    await viewModel.loadMatches(userId: currentUserId)
                }
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

// MARK: - ChatListContent

/// The chat list content, extracted to scope observation.
private struct ChatListContent: View {
    let viewModel: MatchViewModel
    let currentUserId: String

    var body: some View {
        List {
            if viewModel.isLoading {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonChatRow()
                        .listRowSeparator(.hidden)
                }
            } else if viewModel.matches.isEmpty {
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
                    .onAppear {
                        if match.id == viewModel.matches.last?.id {
                            Task {
                                await viewModel.loadMoreMatches(userId: currentUserId)
                            }
                        }
                    }
                }

                if viewModel.isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - ChatRowView

struct ChatRowView: View {
    let match: Match
    let currentUserId: String

    @Environment(\.services) private var services
    @State private var otherUser: ResonanceUser?
    @State private var lastMessage: Message?
    @State private var unreadCount = 0

    var body: some View {
        HStack(spacing: 12) {
            ProfilePhotoView(
                photoURL: otherUser?.photoURL,
                size: 48
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(otherUser?.displayName ?? String(localized: "Loading..."))
                        .font(.headline)

                    Spacer()

                    if let lastMessage {
                        Text(lastMessage.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    } else {
                        Text(match.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                HStack {
                    if let lastMessage {
                        Text(lastMessage.text)
                            .font(.subheadline)
                            .foregroundStyle(unreadCount > 0 ? .primary : .secondary)
                            .fontWeight(unreadCount > 0 ? .semibold : .regular)
                            .lineLimit(1)
                    } else if let song = match.triggerSong {
                        Text(String(localized: "Matched on \(song.name)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.musicRed, in: Capsule())
                    }
                }
            }
        }
        .task {
            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else { return }
            do {
                otherUser = try await services.userService.fetchUser(userId: otherUserId)
            } catch {
                Log.ui.error("Failed to load other user: \(error.localizedDescription)")
            }

            guard let matchId = match.id else { return }
            do {
                lastMessage = try await services.chatService.fetchLastMessage(matchId: matchId)
                unreadCount = try await services.chatService.unreadCount(matchId: matchId, currentUserId: currentUserId)
            } catch {
                Log.ui.error("Failed to load chat preview: \(error.localizedDescription)")
            }
        }
    }
}
