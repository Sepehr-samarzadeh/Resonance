//  ChatViewModel.swift
//  Resonance

import Foundation
import OSLog

// MARK: - ChatViewModel

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Properties

    var messages: [Message] = []
    var messageText = ""
    var isLoading = false
    var errorMessage: String?

    private let chatService: any ChatServiceProtocol

    // MARK: - Init

    init(chatService: some ChatServiceProtocol) {
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
    /// Automatically marks incoming messages from other users as read.
    func listenForMessages(matchId: String, currentUserId: String? = nil) async {
        for await updatedMessages in chatService.messageChanges(matchId: matchId) {
            guard !Task.isCancelled else { return }
            messages = updatedMessages

            // Auto-mark messages as read when new messages from others arrive.
            // Use a detached Task so the mark-as-read actor hop doesn't block the
            // next stream iteration on the MainActor.
            if let currentUserId {
                let hasUnreadFromOthers = updatedMessages.contains { message in
                    message.senderId != currentUserId && !message.isRead
                }
                if hasUnreadFromOthers {
                    Task { [weak self] in
                        await self?.markAsRead(matchId: matchId, currentUserId: currentUserId)
                    }
                }
            }
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
            Log.chat.error("Failed to mark messages as read: \(error.localizedDescription)")
        }
    }
}
