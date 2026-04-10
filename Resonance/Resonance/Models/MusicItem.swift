//  MusicItem.swift
//  Resonance

import Foundation

// MARK: - MusicItem

/// A lightweight representation of a song or artist used throughout the app,
/// decoupled from MusicKit types for Firestore serialization.
struct MusicItem: Codable, Identifiable, Sendable, Hashable {
    var id: String
    var name: String
    var artistName: String?
    var artworkURL: URL?
    var genre: String?
    var durationInSeconds: Int?
}
