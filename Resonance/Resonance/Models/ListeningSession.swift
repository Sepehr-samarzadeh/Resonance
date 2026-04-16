//  ListeningSession.swift
//  Resonance

import Foundation

// MARK: - ListeningSession

struct ListeningSession: Identifiable, Sendable {
    var id: String?
    var songId: String
    var songName: String
    var artistId: String
    var artistName: String
    var genre: String?
    var artworkURL: String?
    var listenedAt: Date
    var durationSeconds: Int
}

// MARK: - ListeningSession + Codable

extension ListeningSession: Codable {
    enum CodingKeys: String, CodingKey {
        case id, songId, songName, artistId, artistName, genre, artworkURL, listenedAt, durationSeconds
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        songId = try container.decodeIfPresent(String.self, forKey: .songId) ?? ""
        songName = try container.decodeIfPresent(String.self, forKey: .songName) ?? ""
        artistId = try container.decodeIfPresent(String.self, forKey: .artistId) ?? ""
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName) ?? ""
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        artworkURL = try container.decodeIfPresent(String.self, forKey: .artworkURL)
        listenedAt = try container.decodeIfPresent(Date.self, forKey: .listenedAt) ?? Date()
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds) ?? 0
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(songId, forKey: .songId)
        try container.encode(songName, forKey: .songName)
        try container.encode(artistId, forKey: .artistId)
        try container.encode(artistName, forKey: .artistName)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encode(listenedAt, forKey: .listenedAt)
        try container.encode(durationSeconds, forKey: .durationSeconds)
    }
}
