//  User.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - User

struct ResonanceUser: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
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
}

// MARK: - AuthProvider

enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
}

// MARK: - TopArtist

struct TopArtist: Codable, Sendable, Identifiable, Hashable {
    var id: String
    var name: String
}

// MARK: - CurrentlyListening

struct CurrentlyListening: Codable, Sendable {
    var songId: String?
    var songName: String?
    var artistName: String?
    var startedAt: Date?
}
