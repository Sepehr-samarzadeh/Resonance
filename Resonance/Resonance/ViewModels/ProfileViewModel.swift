//  ProfileViewModel.swift
//  Resonance

import Foundation
import MusicKit

// MARK: - ProfileViewModel

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Properties

    var user: ResonanceUser?
    var listeningHistory: [ListeningSession] = []
    var isLoading = false
    var isSaving = false
    var isUploadingPhoto = false
    var errorMessage: String?

    // Editable fields
    var editDisplayName = ""
    var editBio = ""
    var editFavoriteGenres: [String] = []

    private let userService: UserService
    private let musicService: MusicService
    private let storageService: StorageService

    // MARK: - Init

    init(userService: UserService, musicService: MusicService, storageService: StorageService) {
        self.userService = userService
        self.musicService = musicService
        self.storageService = storageService
    }

    // MARK: - Load Profile

    /// Loads the user's profile and listening history.
    func loadProfile(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await userService.fetchUser(userId: userId)
            if let user {
                editDisplayName = user.displayName
                editBio = user.bio ?? ""
                editFavoriteGenres = user.favoriteGenres
            }

            listeningHistory = try await userService.fetchListeningHistory(userId: userId, limit: 20)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Save Profile

    /// Saves the edited profile fields to Firestore.
    func saveProfile(userId: String) async {
        isSaving = true
        errorMessage = nil

        do {
            try await userService.updateDisplayName(userId: userId, displayName: editDisplayName)
            try await userService.updateBio(userId: userId, bio: editBio)
            try await userService.updateFavoriteGenres(userId: userId, genres: editFavoriteGenres)

            // Refresh the local user
            user = try await userService.fetchUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Profile Photo

    /// Uploads a profile photo and updates the user's photoURL in Firestore.
    /// - Parameters:
    ///   - imageData: JPEG image data.
    ///   - userId: The user's Firestore document ID.
    func uploadProfilePhoto(imageData: Data, userId: String) async {
        isUploadingPhoto = true
        errorMessage = nil

        do {
            let downloadURL = try await storageService.uploadProfilePhoto(imageData: imageData, userId: userId)
            try await userService.updatePhotoURL(userId: userId, photoURL: downloadURL)
            user = try await userService.fetchUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isUploadingPhoto = false
    }

    // MARK: - Auto-Populate Top Artists

    /// Fetches the user's recently played songs and extracts unique artists.
    func autoPopulateTopArtists(userId: String) async {
        do {
            let songs = try await musicService.fetchRecentlyPlayed()
            var seenArtists: Set<String> = []
            var topArtists: [TopArtist] = []

            for song in songs {
                let artistName = song.artistName
                if !seenArtists.contains(artistName) {
                    seenArtists.insert(artistName)
                    topArtists.append(TopArtist(id: song.id.rawValue, name: artistName))
                }
                if topArtists.count >= Constants.Matching.maxTopArtists { break }
            }

            try await userService.updateTopArtists(userId: userId, artists: topArtists)
            user = try await userService.fetchUser(userId: userId)
        } catch {
            print("ProfileViewModel: Failed to auto-populate top artists — \(error.localizedDescription)")
        }
    }

    // MARK: - Listen for Profile Changes

    /// Starts listening for real-time profile updates.
    func listenForProfileChanges(userId: String) async {
        for await updatedUser in userService.userChanges(userId: userId) {
            user = updatedUser
        }
    }
}
