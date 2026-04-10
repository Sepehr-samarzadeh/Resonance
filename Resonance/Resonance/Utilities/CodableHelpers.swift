//  CodableHelpers.swift
//  Resonance

import Foundation

// MARK: - Nonisolated Codable Helpers

/// Encodes a `Codable` value to a Firestore-compatible dictionary.
/// These helpers are `nonisolated` to avoid Swift 6 strict concurrency issues
/// where `Codable` conformance may be inferred as `@MainActor`-isolated.
nonisolated func encodeToDict<T: Encodable & Sendable>(_ value: T) throws -> [String: Any] {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .secondsSince1970
    let data = try encoder.encode(value)
    let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    return dict
}

/// Decodes a Firestore document dictionary to a `Codable` value.
/// Handles Firestore `Timestamp` objects (dicts with `_seconds` / `_nanoseconds`)
/// by converting them to seconds-since-1970 `Double` before decoding.
nonisolated func decodeFromDict<T: Decodable & Sendable>(_ type: T.Type, from dict: [String: Any]) throws -> T {
    let normalized = normalizeTimestamps(in: dict)
    let data = try JSONSerialization.data(withJSONObject: normalized)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return try decoder.decode(type, from: data)
}

/// Decodes a Firestore document dictionary to a `Codable` value, returning `nil` on failure.
nonisolated func decodeFromDictOptional<T: Decodable & Sendable>(_ type: T.Type, from dict: [String: Any]) -> T? {
    let normalized = normalizeTimestamps(in: dict)
    guard let data = try? JSONSerialization.data(withJSONObject: normalized) else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    return try? decoder.decode(type, from: data)
}

// MARK: - Timestamp Normalization

/// Recursively walks a dictionary and converts Firestore `Timestamp`-like values
/// (dictionaries with `_seconds`/`_nanoseconds` keys, or objects with a `seconds` property)
/// into `Double` values (seconds since 1970) that `JSONDecoder` can decode as `Date`.
private nonisolated func normalizeTimestamps(in dict: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in dict {
        result[key] = normalizeValue(value)
    }
    return result
}

private nonisolated func normalizeValue(_ value: Any) -> Any {
    // Handle Firestore Timestamp serialized as dict with _seconds/_nanoseconds
    if let timestampDict = value as? [String: Any] {
        if let seconds = timestampDict["_seconds"] as? Double {
            let nanos = (timestampDict["_nanoseconds"] as? Double) ?? 0
            return seconds + (nanos / 1_000_000_000)
        }
        if let seconds = timestampDict["seconds"] as? Double {
            let nanos = (timestampDict["nanoseconds"] as? Double) ?? 0
            return seconds + (nanos / 1_000_000_000)
        }
        // Recurse into nested dicts
        return normalizeTimestamps(in: timestampDict)
    }

    // Handle arrays
    if let array = value as? [Any] {
        return array.map { normalizeValue($0) }
    }

    return value
}
