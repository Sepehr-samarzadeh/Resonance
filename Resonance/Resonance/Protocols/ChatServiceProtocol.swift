//  ChatServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - ChatServiceProtocol

/// Protocol defining the interface for chat messaging services.
/// Used by `ChatViewModel` for testability via dependency injection.
protocol ChatServiceProtocol: Sendable {

    /// Sends a text message in a match conversation.
    func sendMessage(matchId: String, senderId: String, text: String) async throws

    /// Fetches all messages for a match, ordered by creation time.
    func fetchMessages(matchId: String, limit: Int) async throws -> [Message]

    /// Returns an `AsyncStream` that emits messages for a match in real time.
    func messageChanges(matchId: String) -> AsyncStream<[Message]>

    /// Deletes a single message from a match conversation.
    func deleteMessage(matchId: String, messageId: String) async throws

    /// Marks all unread messages from other users as read.
    func markMessagesAsRead(matchId: String, currentUserId: String) async throws

    /// Returns the count of unread messages for a user in a match.
    func unreadCount(matchId: String, currentUserId: String) async throws -> Int

    /// Fetches the most recent message in a match conversation.
    func fetchLastMessage(matchId: String) async throws -> Message?
}

// MARK: - Default Parameter Values

extension ChatServiceProtocol {

    /// Convenience overload with default limit of 100.
    func fetchMessages(matchId: String) async throws -> [Message] {
        try await fetchMessages(matchId: matchId, limit: 100)
    }
}
