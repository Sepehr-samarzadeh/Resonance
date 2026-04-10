//  CodableHelpers.swift
//  Resonance

import Foundation

// MARK: - Nonisolated Codable Helpers

/// Encodes a `Codable` value to a Firestore-compatible dictionary.
/// These helpers are `nonisolated` to avoid Swift 6 strict concurrency issues
/// where `Codable` conformance may be inferred as `@MainActor`-isolated.
nonisolated func encodeToDict<T: Encodable & Sendable>(_ value: T) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    return dict
}

/// Decodes a Firestore document dictionary to a `Codable` value.
nonisolated func decodeFromDict<T: Decodable & Sendable>(_ type: T.Type, from dict: [String: Any]) throws -> T {
    let data = try JSONSerialization.data(withJSONObject: dict)
    return try JSONDecoder().decode(type, from: data)
}

/// Decodes a Firestore document dictionary to a `Codable` value, returning `nil` on failure.
nonisolated func decodeFromDictOptional<T: Decodable & Sendable>(_ type: T.Type, from dict: [String: Any]) -> T? {
    guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
    return try? JSONDecoder().decode(type, from: data)
}
