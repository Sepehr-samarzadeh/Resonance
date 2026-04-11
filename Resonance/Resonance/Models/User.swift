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
    var pronouns: String?
    var mood: String?
    var favoriteSong: FavoriteSong?
    var socialLinks: SocialLinks?
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
        case id, displayName, email, photoURL, bio, pronouns, mood
        case favoriteSong, socialLinks, authProvider
        case favoriteGenres, topArtists, currentlyListening, deviceToken
        case createdAt, updatedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        pronouns = try container.decodeIfPresent(String.self, forKey: .pronouns)
        mood = try container.decodeIfPresent(String.self, forKey: .mood)
        favoriteSong = try container.decodeIfPresent(FavoriteSong.self, forKey: .favoriteSong)
        socialLinks = try container.decodeIfPresent(SocialLinks.self, forKey: .socialLinks)
        authProvider = try container.decodeIfPresent(AuthProvider.self, forKey: .authProvider) ?? .apple
        favoriteGenres = try container.decodeIfPresent([String].self, forKey: .favoriteGenres) ?? []
        topArtists = try container.decodeIfPresent([TopArtist].self, forKey: .topArtists) ?? []
        currentlyListening = try container.decodeIfPresent(CurrentlyListening.self, forKey: .currentlyListening)
        deviceToken = try container.decodeIfPresent(String.self, forKey: .deviceToken)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(pronouns, forKey: .pronouns)
        try container.encodeIfPresent(mood, forKey: .mood)
        try container.encodeIfPresent(favoriteSong, forKey: .favoriteSong)
        try container.encodeIfPresent(socialLinks, forKey: .socialLinks)
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
    var artworkURL: String?
}

extension TopArtist: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, artworkURL
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        artworkURL = try container.decodeIfPresent(String.self, forKey: .artworkURL)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
    }
}

// MARK: - CurrentlyListening

struct CurrentlyListening: Sendable, Equatable {
    var songId: String?
    var songName: String?
    var artistName: String?
    var artworkURL: String?
    var startedAt: Date?
}

extension CurrentlyListening: Codable {
    enum CodingKeys: String, CodingKey {
        case songId, songName, artistName, artworkURL, startedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        songId = try container.decodeIfPresent(String.self, forKey: .songId)
        songName = try container.decodeIfPresent(String.self, forKey: .songName)
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        artworkURL = try container.decodeIfPresent(String.self, forKey: .artworkURL)
        startedAt = try container.decodeIfPresent(Date.self, forKey: .startedAt)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(songId, forKey: .songId)
        try container.encodeIfPresent(songName, forKey: .songName)
        try container.encodeIfPresent(artistName, forKey: .artistName)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
    }
}

// MARK: - FavoriteSong

struct FavoriteSong: Sendable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var artistName: String

    enum CodingKeys: String, CodingKey {
        case id, name, artistName
    }

    nonisolated init(id: String, name: String, artistName: String) {
        self.id = id
        self.name = name
        self.artistName = artistName
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        artistName = try container.decodeIfPresent(String.self, forKey: .artistName) ?? ""
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(artistName, forKey: .artistName)
    }
}

// MARK: - SocialLinks

struct SocialLinks: Sendable, Codable, Equatable, Hashable {
    var instagram: String?
    var spotify: String?
    var twitter: String?

    enum CodingKeys: String, CodingKey {
        case instagram, spotify, twitter
    }

    nonisolated init(instagram: String? = nil, spotify: String? = nil, twitter: String? = nil) {
        self.instagram = instagram
        self.spotify = spotify
        self.twitter = twitter
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        spotify = try container.decodeIfPresent(String.self, forKey: .spotify)
        twitter = try container.decodeIfPresent(String.self, forKey: .twitter)
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(instagram, forKey: .instagram)
        try container.encodeIfPresent(spotify, forKey: .spotify)
        try container.encodeIfPresent(twitter, forKey: .twitter)
    }
}
