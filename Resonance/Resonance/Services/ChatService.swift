//  ChatService.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - ChatService

actor ChatService {

    // MARK: - Properties

    private let db = Firestore.firestore()
    private let matchesCollection = "matches"
    private let messagesSubcollection = "messages"

    // MARK: - Send Message

    /// Sends a text message in a match conversation.
    /// - Parameters:
    ///   - matchId: The match document ID.
    ///   - senderId: The sender's user ID.
    ///   - text: The message text.
    func sendMessage(matchId: String, senderId: String, text: String) async throws {
        let message = Message(
            senderId: senderId,
            text: text,
            isRead: false,
            createdAt: Date()
        )
        try db.collection(matchesCollection)
            .document(matchId)
            .collection(messagesSubcollection)
            .addDocument(from: message)
    }

    // MARK: - Fetch Messages

    /// Fetches all messages for a match, ordered by creation time.
    /// - Parameters:
    ///   - matchId: The match document ID.
    ///   - limit: Maximum number of messages to return.
    /// - Returns: An array of `Message`.
    func fetchMessages(matchId: String, limit: Int = 100) async throws -> [Message] {
        let snapshot = try await db.collection(matchesCollection)
            .document(matchId)
            .collection(messagesSubcollection)
            .order(by: "createdAt", descending: false)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: Message.self)
        }
    }

    // MARK: - Real-Time Messages

    /// Returns an `AsyncStream` that emits messages for a match in real time.
    func messageChanges(matchId: String) -> AsyncStream<[Message]> {
        AsyncStream { continuation in
            let listener = db.collection(matchesCollection)
                .document(matchId)
                .collection(messagesSubcollection)
                .order(by: "createdAt", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        print("ChatService: Error listening to messages — \(error.localizedDescription)")
                        return
                    }
                    let messages = snapshot?.documents.compactMap { doc in
                        try? doc.data(as: Message.self)
                    } ?? []
                    continuation.yield(messages)
                }
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }

    // MARK: - Mark as Read

    /// Marks all unread messages from other users as read.
    /// - Parameters:
    ///   - matchId: The match document ID.
    ///   - currentUserId: The current user's ID (messages from this user are skipped).
    func markMessagesAsRead(matchId: String, currentUserId: String) async throws {
        let snapshot = try await db.collection(matchesCollection)
            .document(matchId)
            .collection(messagesSubcollection)
            .whereField("isRead", isEqualTo: false)
            .whereField("senderId", isNotEqualTo: currentUserId)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    // MARK: - Unread Count

    /// Returns the count of unread messages for a user in a match.
    func unreadCount(matchId: String, currentUserId: String) async throws -> Int {
        let snapshot = try await db.collection(matchesCollection)
            .document(matchId)
            .collection(messagesSubcollection)
            .whereField("isRead", isEqualTo: false)
            .whereField("senderId", isNotEqualTo: currentUserId)
            .getDocuments()

        return snapshot.documents.count
    }
}
