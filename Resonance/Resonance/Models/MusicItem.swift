//  MusicItem.swift
//  Resonance

import Foundation

// MARK: - MusicItem

/// A lightweight representation of a song or artist used throughout the app,
/// decoupled from MusicKit types for Firestore serialization.
struct MusicItem: Identifiable, Sendable, Hashable {
    var id: String
    var name: String
    var artistName: String?
    var artworkURL: URL?
    var genre: String?
    var durationInSeconds: Int?
}

// MARK: - MusicItem + Codable

extension MusicItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, artistName, artworkURL, genre, durationInSeconds
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        artworkURL = try container.decodeIfPresent(URL.self, forKey: .artworkURL)
        genre = try container.decodeIfPresent(String.self, forKey: .genre)
        durationInSeconds = try container.decodeIfPresent(Int.self, forKey: .durationInSeconds)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(artistName, forKey: .artistName)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encodeIfPresent(genre, forKey: .genre)
        try container.encodeIfPresent(durationInSeconds, forKey: .durationInSeconds)
    }
}
