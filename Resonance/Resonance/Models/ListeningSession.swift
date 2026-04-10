//  ListeningSession.swift
//  Resonance

import Foundation
import FirebaseFirestore

// MARK: - ListeningSession

struct ListeningSession: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var songId: String
    var songName: String
    var artistId: String
    var artistName: String
    var genre: String?
    var listenedAt: Date
    var durationSeconds: Int
}
