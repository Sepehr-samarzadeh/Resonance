//  Match.swift
//  Resonance

import Foundation

// MARK: - Match

struct Match: Identifiable, Sendable, Hashable {
    var id: String?
    var userIds: [String]
    var matchType: MatchType
    var triggerSong: TriggerSong?
    var triggerArtist: TriggerArtist?
    var similarityScore: Double?
    var createdAt: Date
}

// MARK: - Match + Codable

extension Match: Codable {
    enum CodingKeys: String, CodingKey {
        case id, userIds, matchType, triggerSong, triggerArtist, similarityScore, createdAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        userIds = try container.decodeIfPresent([String].self, forKey: .userIds) ?? []
        matchType = try container.decodeIfPresent(MatchType.self, forKey: .matchType) ?? .historical
        triggerSong = try container.decodeIfPresent(TriggerSong.self, forKey: .triggerSong)
        triggerArtist = try container.decodeIfPresent(TriggerArtist.self, forKey: .triggerArtist)
        similarityScore = try container.decodeIfPresent(Double.self, forKey: .similarityScore)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(userIds, forKey: .userIds)
        try container.encode(matchType, forKey: .matchType)
        try container.encodeIfPresent(triggerSong, forKey: .triggerSong)
        try container.encodeIfPresent(triggerArtist, forKey: .triggerArtist)
        try container.encodeIfPresent(similarityScore, forKey: .similarityScore)
        try container.encode(createdAt, forKey: .createdAt)
    }
}

// MARK: - MatchType

enum MatchType: String, Codable, Sendable {
    case realtime
    case historical
    case discovery
}

// MARK: - TriggerSong

struct TriggerSong: Sendable, Hashable {
    var id: String
    var name: String
    var artistName: String
}

extension TriggerSong: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, artistName
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        artistName = try container.decode(String.self, forKey: .artistName)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(artistName, forKey: .artistName)
    }
}

// MARK: - TriggerArtist

struct TriggerArtist: Sendable, Hashable {
    var id: String
    var name: String
}

extension TriggerArtist: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
    }
}
