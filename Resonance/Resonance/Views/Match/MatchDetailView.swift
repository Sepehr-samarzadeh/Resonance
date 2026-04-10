//  MatchDetailView.swift
//  Resonance

import SwiftUI

// MARK: - MatchDetailView

struct MatchDetailView: View {

    // MARK: - Properties

    let match: Match
    let currentUserId: String
    @State private var otherUser: ResonanceUser?
    @State private var chatViewModel = ChatViewModel()
    private let userService = UserService()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            matchInfoHeader

            Divider()

            chatSection
        }
        .navigationTitle(otherUser?.displayName ?? String(localized: "Match"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else { return }
            otherUser = try? await userService.fetchUser(userId: otherUserId)

            if let matchId = match.id {
                await chatViewModel.listenForMessages(matchId: matchId)
            }
        }
    }

    // MARK: - Match Info Header

    private var matchInfoHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.purple.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                }

            Text(otherUser?.displayName ?? "")
                .font(.title3)
                .fontWeight(.semibold)

            if let song = match.triggerSong {
                Label(song.name, systemImage: "music.note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let score = match.similarityScore {
                MatchScoreBadge(score: score)
            }
        }
        .padding()
    }

    // MARK: - Chat Section

    private var chatSection: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chatViewModel.messages) { message in
                        ChatBubble(message: message, isFromCurrentUser: message.senderId == currentUserId)
                    }
                }
                .padding()
            }

            Divider()

            chatInputBar
        }
    }

    // MARK: - Chat Input

    private var chatInputBar: some View {
        HStack(spacing: 12) {
            TextField(String(localized: "Message..."), text: $chatViewModel.messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Button {
                guard let matchId = match.id else { return }
                Task {
                    await chatViewModel.sendMessage(matchId: matchId, senderId: currentUserId)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .disabled(chatViewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

// MARK: - ChatBubble

struct ChatBubble: View {
    let message: Message
    let isFromCurrentUser: Bool

    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }

            Text(message.text)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isFromCurrentUser ? .purple : Color(.systemGray5))
                .foregroundStyle(isFromCurrentUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            if !isFromCurrentUser { Spacer() }
        }
    }
}
