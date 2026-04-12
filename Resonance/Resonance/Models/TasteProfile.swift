//  TasteProfile.swift
//  Resonance

import Foundation

// MARK: - TasteProfile

/// A user's music taste profile, populated during onboarding.
/// Used for historical matching so new users can be matched immediately
/// without needing listening history.
struct TasteProfile: Sendable, Equatable, Hashable {

    /// Genres the user selected during onboarding (e.g. "Pop", "Rock", "Hip-Hop").
    var selectedGenres: [String]

    /// Artists the user explicitly picked during onboarding.
    var selectedArtists: [TasteArtist]

    /// Artist names extracted from the user's Apple Music library.
    /// Stored as lowercase-normalized names for efficient comparison.
    var libraryArtistNames: [String]

    /// When the taste profile was last updated.
    var updatedAt: Date

    init(
        selectedGenres: [String] = [],
        selectedArtists: [TasteArtist] = [],
        libraryArtistNames: [String] = [],
        updatedAt: Date = Date()
    ) {
        self.selectedGenres = selectedGenres
        self.selectedArtists = selectedArtists
        self.libraryArtistNames = libraryArtistNames
        self.updatedAt = updatedAt
    }
}

// MARK: - TasteProfile + Codable

extension TasteProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case selectedGenres, selectedArtists, libraryArtistNames, updatedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedGenres = try container.decodeIfPresent([String].self, forKey: .selectedGenres) ?? []
        selectedArtists = try container.decodeIfPresent([TasteArtist].self, forKey: .selectedArtists) ?? []
        libraryArtistNames = try container.decodeIfPresent([String].self, forKey: .libraryArtistNames) ?? []
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(selectedGenres, forKey: .selectedGenres)
        try container.encode(selectedArtists, forKey: .selectedArtists)
        try container.encode(libraryArtistNames, forKey: .libraryArtistNames)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - TasteArtist

/// A lightweight artist reference stored in the taste profile.
struct TasteArtist: Sendable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var artworkURL: String?

    init(id: String, name: String, artworkURL: String? = nil) {
        self.id = id
        self.name = name
        self.artworkURL = artworkURL
    }
}

// MARK: - TasteArtist + Codable

extension TasteArtist: Codable {
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
