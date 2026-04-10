//  Match.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - Match

struct Match: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var userIds: [String]
    var matchType: MatchType
    var triggerSong: TriggerSong?
    var triggerArtist: TriggerArtist?
    var similarityScore: Double?
    var createdAt: Date
}

// MARK: - MatchType

enum MatchType: String, Codable, Sendable {
    case realtime
    case historical
}

// MARK: - TriggerSong

struct TriggerSong: Codable, Sendable {
    var id: String
    var name: String
    var artistName: String
}

// MARK: - TriggerArtist

struct TriggerArtist: Codable, Sendable {
    var id: String
    var name: String
}
