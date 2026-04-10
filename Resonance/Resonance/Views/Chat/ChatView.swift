//  ChatView.swift
//  Resonance

import SwiftUI

// MARK: - ChatView

struct ChatView: View {

    // MARK: - Properties

    @State private var viewModel = ChatViewModel()
    let matchId: String
    let currentUserId: String
    let otherUserName: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            messagesList

            Divider()

            inputBar
        }
        .navigationTitle(otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.listenForMessages(matchId: matchId)
            await viewModel.markAsRead(matchId: matchId, currentUserId: currentUserId)
        }
    }

    // MARK: - Messages List

    private var messagesList: some View {
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

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField(String(localized: "Type a message..."), text: $viewModel.messageText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())

            Button {
                Task {
                    await viewModel.sendMessage(matchId: matchId, senderId: currentUserId)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .disabled(viewModel.messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
