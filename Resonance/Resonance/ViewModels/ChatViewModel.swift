//  ChatViewModel.swift
//  Resonance

import Foundation

// MARK: - ChatViewModel

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Properties

    var messages: [Message] = []
    var messageText = ""
    var isLoading = false
    var errorMessage: String?

    private let chatService: ChatService

    // MARK: - Init

    init(chatService: ChatService) {
        self.chatService = chatService
    }

    // MARK: - Load Messages

    /// Fetches messages for a match.
    func loadMessages(matchId: String) async {
        isLoading = true

        do {
            messages = try await chatService.fetchMessages(matchId: matchId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Listen for Messages

    /// Starts listening for real-time message updates.
    func listenForMessages(matchId: String) async {
        for await updatedMessages in await chatService.messageChanges(matchId: matchId) {
            messages = updatedMessages
        }
    }

    // MARK: - Send Message

    /// Sends a text message in the match conversation.
    func sendMessage(matchId: String, senderId: String) async {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        do {
            try await chatService.sendMessage(matchId: matchId, senderId: senderId, text: text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mark as Read

    /// Marks unread messages from the other user as read.
    func markAsRead(matchId: String, currentUserId: String) async {
        do {
            try await chatService.markMessagesAsRead(matchId: matchId, currentUserId: currentUserId)
        } catch {
            print("ChatViewModel: Failed to mark messages as read — \(error.localizedDescription)")
        }
    }
}
