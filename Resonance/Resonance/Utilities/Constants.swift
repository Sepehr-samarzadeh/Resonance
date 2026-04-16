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

    // MARK: - Profile Limits

    enum ProfileLimits {
        static let displayNameMax = 50
        static let bioMax = 300
        static let pronounsMax = 30
        static let moodMax = 100
        static let songNameMax = 100
        static let artistNameMax = 100
        static let usernameMax = 30
        static let maxGenres = 10
    }

    // MARK: - Legal

    enum Legal {
        // TODO: Replace with actual URLs before App Store submission
        static let privacyPolicyURL = URL(string: "https://resonance.app/privacy")!
        static let termsOfServiceURL = URL(string: "https://resonance.app/terms")!
    }

    // MARK: - Music Genres

    /// Apple Music genre list used for onboarding and profile editing.
    enum Genres {
        static let all: [String] = [
            "Pop", "Rock", "Hip-Hop", "R&B", "Jazz", "Classical",
            "Electronic", "Country", "Latin", "Metal", "Indie",
            "Alternative", "Soul", "Funk", "Reggae", "Blues",
            "Folk", "Punk", "K-Pop", "J-Pop", "Afrobeats",
            "Dance", "Lo-Fi", "Ambient", "Gospel", "Soundtrack"
        ]

        static let emojis: [String: String] = [
            "Pop": "🎤", "Rock": "🎸", "Hip-Hop": "🎙️", "R&B": "🎵",
            "Jazz": "🎷", "Classical": "🎻", "Electronic": "🎛️", "Country": "🤠",
            "Latin": "💃", "Metal": "🤘", "Indie": "🎹", "Alternative": "🔊",
            "Soul": "❤️", "Funk": "🕺", "Reggae": "🌴", "Blues": "🎺",
            "Folk": "🪕", "Punk": "⚡", "K-Pop": "🇰🇷", "J-Pop": "🇯🇵",
            "Afrobeats": "🥁", "Dance": "🪩", "Lo-Fi": "☕", "Ambient": "🌊",
            "Gospel": "🙏", "Soundtrack": "🎬"
        ]
    }
}
