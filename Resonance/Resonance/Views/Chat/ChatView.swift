//  ChatView.swift
//  Resonance

import SwiftUI

// MARK: - ChatView

struct ChatView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: ChatViewModel?
    @State private var otherUser: ResonanceUser?

    let match: Match
    let currentUserId: String

    private var otherUserName: String {
        otherUser?.displayName ?? String(localized: "Chat")
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                chatContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel == nil {
                viewModel = ChatViewModel(chatService: services.chatService)
            }

            // Load other user
            if let otherUserId = match.userIds.first(where: { $0 != currentUserId }) {
                do {
                    otherUser = try await services.userService.fetchUser(userId: otherUserId)
                } catch {
                    print("ChatView: Failed to load other user — \(error.localizedDescription)")
                }
            }

            if let matchId = match.id {
                await viewModel?.listenForMessages(matchId: matchId)
                await viewModel?.markAsRead(matchId: matchId, currentUserId: currentUserId)
            }
        }
    }

    // MARK: - Chat Content

    @ViewBuilder
    private func chatContent(viewModel: ChatViewModel) -> some View {
        VStack(spacing: 0) {
            messagesList(viewModel: viewModel)

            Divider()

            inputBar(viewModel: viewModel)
        }
    }

    // MARK: - Messages List

    @ViewBuilder
    private func messagesList(viewModel: ChatViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(viewModel.messages) { message in
                    ChatBubble(
                        message: message,
                        isFromCurrentUser: message.senderId == currentUserId
                    )
                }
            }
            .padding()
        }
        .defaultScrollAnchor(.bottom)
    }

    // MARK: - Input Bar

    @ViewBuilder
    private func inputBar(viewModel: ChatViewModel) -> some View {
        @Bindable var vm = viewModel
        HStack(spacing: 12) {
            TextField(String(localized: "Type a message..."), text: $vm.messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Button {
                guard let matchId = match.id else { return }
                Task {
                    await viewModel.sendMessage(matchId: matchId, senderId: currentUserId)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .accessibilityLabel(String(localized: "Send message"))
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
