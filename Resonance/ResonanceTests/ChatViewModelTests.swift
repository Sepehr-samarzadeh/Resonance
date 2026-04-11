//  ChatViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - ChatViewModelTests

@MainActor
@Suite("ChatViewModel Tests")
struct ChatViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        chatService: MockChatService = MockChatService()
    ) -> (viewModel: ChatViewModel, chat: MockChatService) {
        let vm = ChatViewModel(chatService: chatService)
        return (vm, chatService)
    }

    // MARK: - Load Messages

    @Test("loadMessages populates messages on success")
    func loadMessagesSuccess() async {
        let chat = MockChatService()
        let testMessages = [
            TestData.makeMessage(id: "msg-1", text: "Hello"),
            TestData.makeMessage(id: "msg-2", text: "World"),
        ]
        chat.stubbedFetchMessagesResult = .success(testMessages)

        let (vm, _) = makeSUT(chatService: chat)

        await vm.loadMessages(matchId: "match-1")

        #expect(vm.messages.count == 2)
        #expect(vm.messages[0].text == "Hello")
        #expect(vm.messages[1].text == "World")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadMessages sets errorMessage on failure")
    func loadMessagesFailure() async {
        let chat = MockChatService()
        chat.stubbedFetchMessagesResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Load failed"]))

        let (vm, _) = makeSUT(chatService: chat)

        await vm.loadMessages(matchId: "match-1")

        #expect(vm.messages.isEmpty)
        #expect(vm.errorMessage == "Load failed")
        #expect(vm.isLoading == false)
    }

    // MARK: - Send Message

    @Test("sendMessage sends trimmed text and clears messageText")
    func sendMessageSuccess() async {
        let chat = MockChatService()

        let (vm, _) = makeSUT(chatService: chat)
        vm.messageText = "  Hello there!  "

        await vm.sendMessage(matchId: "match-1", senderId: "user-1")

        #expect(vm.messageText.isEmpty)
        #expect(chat.sendMessageCallCount == 1)
        #expect(chat.capturedSendMessageText == "Hello there!")
        #expect(chat.capturedSendMessageSenderId == "user-1")
        #expect(chat.capturedMatchId == "match-1")
        #expect(vm.errorMessage == nil)
    }

    @Test("sendMessage does nothing for empty text")
    func sendMessageEmpty() async {
        let chat = MockChatService()

        let (vm, _) = makeSUT(chatService: chat)
        vm.messageText = "   "

        await vm.sendMessage(matchId: "match-1", senderId: "user-1")

        #expect(chat.sendMessageCallCount == 0)
    }

    @Test("sendMessage does nothing for whitespace-only text")
    func sendMessageWhitespace() async {
        let chat = MockChatService()

        let (vm, _) = makeSUT(chatService: chat)
        vm.messageText = "\n\t  "

        await vm.sendMessage(matchId: "match-1", senderId: "user-1")

        #expect(chat.sendMessageCallCount == 0)
    }

    @Test("sendMessage sets errorMessage on failure")
    func sendMessageFailure() async {
        let chat = MockChatService()
        chat.stubbedSendMessageError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Send failed"])

        let (vm, _) = makeSUT(chatService: chat)
        vm.messageText = "Hello"

        await vm.sendMessage(matchId: "match-1", senderId: "user-1")

        #expect(vm.errorMessage == "Send failed")
        #expect(vm.messageText.isEmpty) // Text is cleared before sending
    }

    // MARK: - Listen for Messages

    @Test("listenForMessages updates messages from stream")
    func listenForMessages() async {
        let chat = MockChatService()
        let testMessages = [TestData.makeMessage(id: "msg-live", text: "Live message")]
        chat.stubbedMessageChanges = [testMessages]

        let (vm, _) = makeSUT(chatService: chat)

        await vm.listenForMessages(matchId: "match-1")

        #expect(vm.messages.count == 1)
        #expect(vm.messages[0].text == "Live message")
    }

    @Test("listenForMessages auto-marks unread messages from others as read")
    func listenForMessagesAutoRead() async {
        let chat = MockChatService()
        let testMessages = [
            TestData.makeMessage(id: "msg-1", senderId: "user-2", text: "Hey", isRead: false),
        ]
        chat.stubbedMessageChanges = [testMessages]

        let (vm, _) = makeSUT(chatService: chat)

        await vm.listenForMessages(matchId: "match-1", currentUserId: "user-1")

        #expect(chat.markMessagesAsReadCallCount == 1)
    }

    @Test("listenForMessages does not mark own messages as read")
    func listenForMessagesNoAutoReadForOwnMessages() async {
        let chat = MockChatService()
        let testMessages = [
            TestData.makeMessage(id: "msg-1", senderId: "user-1", text: "My message", isRead: false),
        ]
        chat.stubbedMessageChanges = [testMessages]

        let (vm, _) = makeSUT(chatService: chat)

        await vm.listenForMessages(matchId: "match-1", currentUserId: "user-1")

        #expect(chat.markMessagesAsReadCallCount == 0)
    }

    // MARK: - Mark as Read

    @Test("markAsRead calls chatService.markMessagesAsRead")
    func markAsRead() async {
        let chat = MockChatService()

        let (vm, _) = makeSUT(chatService: chat)

        await vm.markAsRead(matchId: "match-1", currentUserId: "user-1")

        #expect(chat.markMessagesAsReadCallCount == 1)
    }

    @Test("markAsRead handles error silently")
    func markAsReadError() async {
        let chat = MockChatService()
        chat.stubbedMarkMessagesAsReadError = NSError(domain: "test", code: 1)

        let (vm, _) = makeSUT(chatService: chat)

        await vm.markAsRead(matchId: "match-1", currentUserId: "user-1")

        // Should not set errorMessage for mark-as-read failures (silent)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Loading State

    @Test("loadMessages toggles isLoading")
    func loadMessagesLoading() async {
        let chat = MockChatService()
        chat.stubbedFetchMessagesResult = .success([])

        let (vm, _) = makeSUT(chatService: chat)

        #expect(vm.isLoading == false)

        await vm.loadMessages(matchId: "match-1")

        #expect(vm.isLoading == false)
    }
}
