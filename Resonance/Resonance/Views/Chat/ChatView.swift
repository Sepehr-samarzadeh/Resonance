//  ChatView.swift
//  Resonance

import SwiftUI
import OSLog

// MARK: - ChatView

struct ChatView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: ChatViewModel?
    @State private var otherUser: ResonanceUser?
    @State private var didLoadUser = false

    let match: Match
    let currentUserId: String

    private var otherUserName: String {
        otherUser?.displayName ?? (didLoadUser ? String(localized: "Resonance User") : String(localized: "Chat"))
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

            // Load other user info
            if let otherUserId = match.userIds.first(where: { $0 != currentUserId }) {
                do {
                    otherUser = try await services.userService.fetchUser(userId: otherUserId)
                } catch {
                    Log.ui.error("Failed to load other user: \(error.localizedDescription)")
                }
            }
            didLoadUser = true
        }
        .task(id: match.id) {
            guard let matchId = match.id else { return }
            if viewModel == nil {
                viewModel = ChatViewModel(chatService: services.chatService)
            }
            await viewModel?.listenForMessages(matchId: matchId, currentUserId: currentUserId)
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
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
                if viewModel.messages.isEmpty {
                    ContentUnavailableView(
                        String(localized: "No Messages Yet"),
                        systemImage: "bubble.left.and.text.bubble.right",
                        description: Text(String(localized: "Say hello and start the conversation!"))
                    )
                    .padding(.top, 60)
                } else {
                    ForEach(viewModel.messages) { message in
                        let isOwn = message.senderId == currentUserId
                        ChatBubble(
                            message: message,
                            isFromCurrentUser: isOwn,
                            onDelete: isOwn ? {
                                guard let messageId = message.id else { return }
                                Task {
                                    await viewModel.deleteMessage(
                                        matchId: match.id ?? "",
                                        messageId: messageId
                                    )
                                }
                            } : nil
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
            }
            .padding()
            .animation(.easeOut(duration: 0.25), value: viewModel.messages.count)
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
                    .foregroundStyle(.musicRed)
            }
            .accessibilityLabel(String(localized: "Send message"))
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.messages.count)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
