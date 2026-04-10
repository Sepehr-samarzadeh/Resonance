//  Message.swift
//  Resonance

import Foundation

// MARK: - Message

struct Message: Identifiable, Sendable {
    var id: String?
    var senderId: String
    var text: String
    var isRead: Bool
    var createdAt: Date
}

// MARK: - Message + Codable

extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id, senderId, text, isRead, createdAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        senderId = try container.decode(String.self, forKey: .senderId)
        text = try container.decode(String.self, forKey: .text)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(text, forKey: .text)
        try container.encode(isRead, forKey: .isRead)
        try container.encode(createdAt, forKey: .createdAt)
    }
}
