//  User.swift
//  Resonance

import Foundation

// MARK: - User

struct ResonanceUser: Identifiable, Sendable, Hashable {
    var id: String?
    var displayName: String
    var email: String
    var photoURL: String?
    var bio: String?
    var authProvider: AuthProvider
    var favoriteGenres: [String]
    var topArtists: [TopArtist]
    var currentlyListening: CurrentlyListening?
    var deviceToken: String?
    var createdAt: Date
    var updatedAt: Date

    static func == (lhs: ResonanceUser, rhs: ResonanceUser) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ResonanceUser + Codable

extension ResonanceUser: Codable {
    enum CodingKeys: String, CodingKey {
        case id, displayName, email, photoURL, bio, authProvider
        case favoriteGenres, topArtists, currentlyListening, deviceToken
        case createdAt, updatedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        authProvider = try container.decode(AuthProvider.self, forKey: .authProvider)
        favoriteGenres = try container.decode([String].self, forKey: .favoriteGenres)
        topArtists = try container.decode([TopArtist].self, forKey: .topArtists)
        currentlyListening = try container.decodeIfPresent(CurrentlyListening.self, forKey: .currentlyListening)
        deviceToken = try container.decodeIfPresent(String.self, forKey: .deviceToken)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encode(authProvider, forKey: .authProvider)
        try container.encode(favoriteGenres, forKey: .favoriteGenres)
        try container.encode(topArtists, forKey: .topArtists)
        try container.encodeIfPresent(currentlyListening, forKey: .currentlyListening)
        try container.encodeIfPresent(deviceToken, forKey: .deviceToken)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - AuthProvider

enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
}

// MARK: - TopArtist

struct TopArtist: Sendable, Identifiable, Hashable {
    var id: String
    var name: String
}

extension TopArtist: Codable {
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

// MARK: - CurrentlyListening

struct CurrentlyListening: Sendable {
    var songId: String?
    var songName: String?
    var artistName: String?
    var startedAt: Date?
}

extension CurrentlyListening: Codable {
    enum CodingKeys: String, CodingKey {
        case songId, songName, artistName, startedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songId = try container.decodeIfPresent(String.self, forKey: .songId)
        songName = try container.decodeIfPresent(String.self, forKey: .songName)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(songId, forKey: .songId)
        try container.encodeIfPresent(songName, forKey: .songName)
        try container.encodeIfPresent(artistName, forKey: .artistName)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
    }
}
