//  UserServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - UserServiceProtocol

/// Protocol defining the interface for user management services.
/// Used by `AuthViewModel`, `HomeViewModel`, `PlayerViewModel`,
/// `MatchViewModel`, and `ProfileViewModel` for testability.
protocol UserServiceProtocol: Sendable {

    /// Fetches a user document from Firestore by ID.
    func fetchUser(userId: String) async throws -> ResonanceUser?

    /// Updates the user's profile fields in Firestore.
    func updateProfile(_ user: ResonanceUser) async throws

    /// Updates the user's display name.
    func updateDisplayName(userId: String, displayName: String) async throws

    /// Updates the user's bio.
    func updateBio(userId: String, bio: String) async throws

    /// Updates the user's photo URL.
    func updatePhotoURL(userId: String, photoURL: String) async throws

    /// Updates the user's favorite genres.
    func updateFavoriteGenres(userId: String, genres: [String]) async throws

    /// Updates the user's top artists.
    func updateTopArtists(userId: String, artists: [TopArtist]) async throws

    /// Updates the user's pronouns.
    func updatePronouns(userId: String, pronouns: String?) async throws

    /// Updates the user's mood / status message.
    func updateMood(userId: String, mood: String?) async throws

    /// Updates the user's favorite song.
    func updateFavoriteSong(userId: String, song: FavoriteSong?) async throws

    /// Updates the user's social links.
    func updateSocialLinks(userId: String, links: SocialLinks?) async throws

    /// Updates the user's currently listening status.
    func updateCurrentlyListening(userId: String, listening: CurrentlyListening?) async throws

    // MARK: - Taste Profile

    /// Saves or updates the user's taste profile (genres, artists, library data).
    func saveTasteProfile(userId: String, profile: TasteProfile) async throws

    /// Fetches just the taste profile for a user.
    func fetchTasteProfile(userId: String) async throws -> TasteProfile?

    // MARK: - Listening History

    /// Saves a listening session to the user's history subcollection.
    func saveListeningSession(userId: String, session: ListeningSession) async throws

    /// Fetches the user's listening history, ordered by most recent.
    func fetchListeningHistory(userId: String, limit: Int) async throws -> [ListeningSession]

    /// Returns an `AsyncStream` that emits user document changes in real time.
    func userChanges(userId: String) -> AsyncStream<ResonanceUser?>

    // MARK: - Imported Playlists

    /// Saves an imported playlist to the user's `importedPlaylists` subcollection.
    func saveImportedPlaylist(userId: String, playlist: ImportedPlaylist) async throws

    /// Fetches all imported playlists for a user, ordered by import date.
    func fetchImportedPlaylists(userId: String) async throws -> [ImportedPlaylist]

    /// Deletes an imported playlist from the user's subcollection.
    func deleteImportedPlaylist(userId: String, playlistId: String) async throws

    // MARK: - Account Deletion

    /// Deletes all user data from Firestore (user document, listening history, imported playlists).
    func deleteAllUserData(userId: String) async throws
}
