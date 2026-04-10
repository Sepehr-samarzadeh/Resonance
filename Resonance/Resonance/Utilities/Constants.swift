//  Constants.swift
//  Resonance

import Foundation

// MARK: - Constants

enum Constants {

    // MARK: - Firestore Collections

    enum Collections {
        static let users = "users"
        static let matches = "matches"
        static let messages = "messages"
        static let listeningHistory = "listeningHistory"
        static let sessions = "sessions"
    }

    // MARK: - App Storage Keys

    enum StorageKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isSignedIn = "isSignedIn"
    }

    // MARK: - Matching

    enum Matching {
        static let historicalThreshold: Double = 0.3
        static let maxListeningHistoryCompare = 100
        static let maxTopArtists = 10
    }

    // MARK: - UI

    enum UI {
        static let artworkSmallSize: CGFloat = 48
        static let artworkMediumSize: CGFloat = 64
        static let artworkLargeSize: CGFloat = 300
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 20
    }
}
