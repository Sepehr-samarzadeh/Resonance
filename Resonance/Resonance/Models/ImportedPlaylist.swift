//  ImportedPlaylist.swift
//  Resonance

import Foundation

// MARK: - ImportedPlaylist

/// A playlist imported from the user's Apple Music library, stored in Firestore.
struct ImportedPlaylist: Identifiable, Sendable, Hashable {
    var id: String
    var name: String
    var description: String?
    var curatorName: String?
    var trackCount: Int
    var artworkURL: String?
    var importedAt: Date

    static func == (lhs: ImportedPlaylist, rhs: ImportedPlaylist) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ImportedPlaylist + Codable

extension ImportedPlaylist: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, description, curatorName, trackCount, artworkURL, importedAt
    }

    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        curatorName = try container.decodeIfPresent(String.self, forKey: .curatorName)
        trackCount = try container.decodeIfPresent(Int.self, forKey: .trackCount) ?? 0
        artworkURL = try container.decodeIfPresent(String.self, forKey: .artworkURL)
        importedAt = try container.decodeIfPresent(Date.self, forKey: .importedAt) ?? Date()
    }

    nonisolated func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(curatorName, forKey: .curatorName)
        try container.encode(trackCount, forKey: .trackCount)
        try container.encodeIfPresent(artworkURL, forKey: .artworkURL)
        try container.encode(importedAt, forKey: .importedAt)
    }
}
