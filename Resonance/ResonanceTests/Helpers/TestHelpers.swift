//  TestHelpers.swift
//  ResonanceTests

import Foundation
@testable import Resonance

// MARK: - Test Data Helpers

enum TestData {

    static func makeUser(
        id: String = "user-1",
        displayName: String = "Test User",
        email: String = "test@example.com",
        photoURL: String? = nil,
        bio: String? = "A music lover",
        pronouns: String? = nil,
        mood: String? = nil,
        favoriteSong: FavoriteSong? = nil,
        socialLinks: SocialLinks? = nil,
        authProvider: AuthProvider = .apple,
        favoriteGenres: [String] = ["Pop", "Rock"],
        topArtists: [TopArtist] = [TopArtist(id: "artist-1", name: "Test Artist")],
        currentlyListening: CurrentlyListening? = nil,
        deviceToken: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> ResonanceUser {
        ResonanceUser(
            id: id,
            displayName: displayName,
            email: email,
            photoURL: photoURL,
            bio: bio,
            pronouns: pronouns,
            mood: mood,
            favoriteSong: favoriteSong,
            socialLinks: socialLinks,
            authProvider: authProvider,
            favoriteGenres: favoriteGenres,
            topArtists: topArtists,
            currentlyListening: currentlyListening,
            deviceToken: deviceToken,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    static func makeMatch(
        id: String = "match-1",
        userIds: [String] = ["user-1", "user-2"],
        matchType: MatchType = .realtime,
        triggerSong: TriggerSong? = TriggerSong(id: "song-1", name: "Test Song", artistName: "Test Artist"),
        triggerArtist: TriggerArtist? = nil,
        similarityScore: Double? = nil,
        createdAt: Date = Date()
    ) -> Match {
        Match(
            id: id,
            userIds: userIds,
            matchType: matchType,
            triggerSong: triggerSong,
            triggerArtist: triggerArtist,
            similarityScore: similarityScore,
            createdAt: createdAt
        )
    }

    static func makeMessage(
        id: String = "msg-1",
        senderId: String = "user-1",
        text: String = "Hello!",
        isRead: Bool = false,
        createdAt: Date = Date()
    ) -> Message {
        Message(
            id: id,
            senderId: senderId,
            text: text,
            isRead: isRead,
            createdAt: createdAt
        )
    }

    static func makeListeningSession(
        id: String = UUID().uuidString,
        songId: String = "song-1",
        songName: String = "Test Song",
        artistId: String = "artist-1",
        artistName: String = "Test Artist",
        genre: String? = "Pop",
        artworkURL: String? = nil,
        listenedAt: Date = Date(),
        durationSeconds: Int = 200
    ) -> ListeningSession {
        ListeningSession(
            id: id,
            songId: songId,
            songName: songName,
            artistId: artistId,
            artistName: artistName,
            genre: genre,
            artworkURL: artworkURL,
            listenedAt: listenedAt,
            durationSeconds: durationSeconds
        )
    }
}
