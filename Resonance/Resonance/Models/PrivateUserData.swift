//  PrivateUserData.swift
//  Resonance

import Foundation

// MARK: - PrivateUserData

/// Sensitive user data stored in `users/{userId}/private/profile`.
/// Only readable by the owning user. Separated from the public user
/// document to prevent other authenticated users from accessing
/// email addresses, blocked lists, etc.
struct PrivateUserData: Codable, Sendable {
    var email: String
    var blockedUserIds: [String]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case email, blockedUserIds
    }

    nonisolated init(email: String = "", blockedUserIds: [String] = []) {
        self.email = email
        self.blockedUserIds = blockedUserIds
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        blockedUserIds = try container.decodeIfPresent([String].self, forKey: .blockedUserIds) ?? []
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(blockedUserIds, forKey: .blockedUserIds)
    }
}
