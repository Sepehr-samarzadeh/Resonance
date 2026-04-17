//  FriendRequest.swift
//  Resonance

import Foundation

// MARK: - FriendRequest

struct FriendRequest: Identifiable, Sendable, Hashable {
    var id: String?
    var senderId: String
    var receiverId: String
    var status: RequestStatus
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - FriendRequest + Codable

extension FriendRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case id, senderId, receiverId, status, createdAt, updatedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        senderId = try container.decodeIfPresent(String.self, forKey: .senderId) ?? ""
        receiverId = try container.decodeIfPresent(String.self, forKey: .receiverId) ?? ""
        status = try container.decodeIfPresent(RequestStatus.self, forKey: .status) ?? .pending
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(receiverId, forKey: .receiverId)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - RequestStatus

enum RequestStatus: String, Codable, Sendable {
    case pending
    case accepted
    case declined
}
