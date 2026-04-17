//  Log.swift
//  Resonance

import OSLog

// MARK: - Log

/// Centralized structured loggers for each subsystem category.
/// Usage: `Log.auth.error("Failed to load profile: \(error)")`
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.resonance"

    /// Authentication and sign-in events.
    static let auth = Logger(subsystem: subsystem, category: "auth")

    /// Chat and messaging events.
    static let chat = Logger(subsystem: subsystem, category: "chat")

    /// Match discovery and matching events.
    static let match = Logger(subsystem: subsystem, category: "match")

    /// Music playback and MusicKit events.
    static let music = Logger(subsystem: subsystem, category: "music")

    /// Push notification events.
    static let notification = Logger(subsystem: subsystem, category: "notification")

    /// User profile and Firestore user document events.
    static let user = Logger(subsystem: subsystem, category: "user")

    /// General UI and view-layer events.
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Discovery and friend request events.
    static let discovery = Logger(subsystem: subsystem, category: "discovery")
}
