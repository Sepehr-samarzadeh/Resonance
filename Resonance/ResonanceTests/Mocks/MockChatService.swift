//  MockChatService.swift
//  ResonanceTests

import Foundation
@testable import Resonance

final class MockChatService: ChatServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var sendMessageCallCount = 0
    var fetchMessagesCallCount = 0
    var messageChangesCallCount = 0
    var markMessagesAsReadCallCount = 0
    var unreadCountCallCount = 0
    var fetchLastMessageCallCount = 0

    // MARK: - Stubbed Results

    var stubbedSendMessageError: Error?
    var stubbedFetchMessagesResult: Result<[Message], Error> = .success([])
    var stubbedMessageChanges: [[Message]] = []
    var stubbedMarkMessagesAsReadError: Error?
    var stubbedUnreadCount = 0
    var stubbedLastMessage: Message?

    // MARK: - Captured Values

    var capturedSendMessageText: String?
    var capturedSendMessageSenderId: String?
    var capturedMatchId: String?

    // MARK: - Protocol Methods

    func sendMessage(matchId: String, senderId: String, text: String) async throws {
        sendMessageCallCount += 1
        capturedMatchId = matchId
        capturedSendMessageSenderId = senderId
        capturedSendMessageText = text
        if let error = stubbedSendMessageError { throw error }
    }

    func fetchMessages(matchId: String, limit: Int) async throws -> [Message] {
        fetchMessagesCallCount += 1
        capturedMatchId = matchId
        return try stubbedFetchMessagesResult.get()
    }

    func messageChanges(matchId: String) -> AsyncStream<[Message]> {
        messageChangesCallCount += 1
        return AsyncStream { continuation in
            for messages in stubbedMessageChanges {
                continuation.yield(messages)
            }
            continuation.finish()
        }
    }

    func markMessagesAsRead(matchId: String, currentUserId: String) async throws {
        markMessagesAsReadCallCount += 1
        if let error = stubbedMarkMessagesAsReadError { throw error }
    }

    func unreadCount(matchId: String, currentUserId: String) async throws -> Int {
        unreadCountCallCount += 1
        return stubbedUnreadCount
    }

    func fetchLastMessage(matchId: String) async throws -> Message? {
        fetchLastMessageCallCount += 1
        return stubbedLastMessage
    }
}
