//  Message.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - Message

struct Message: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var senderId: String
    var text: String
    var isRead: Bool
    var createdAt: Date
}
