//  ProfileViewModel.swift
//  Resonance

import Foundation
import MusicKit
import OSLog

// MARK: - ProfileViewModel

@MainActor
@Observable
final class ProfileViewModel {

    // MARK: - Properties

    var user: ResonanceUser?
    var listeningHistory: [ListeningSession] = []
    var importedPlaylists: [ImportedPlaylist] = []
    var onRepeatSongs: [OnRepeatSong] = []
    var isLoading = false
    var isSaving = false
    var isUploadingPhoto = false
    var errorMessage: String?

    // Editable fields
    var editDisplayName = ""
    var editBio = ""
    var editPronouns = ""
    var editMood = ""
    var editFavoriteSongName = ""
    var editFavoriteSongArtist = ""
    var editInstagram = ""
    var editSpotify = ""
    var editTwitter = ""
    var editFavoriteGenres: [String] = []

    private let userService: any UserServiceProtocol
    private let musicService: any MusicServiceProtocol
    private let storageService: any StorageServiceProtocol

    // MARK: - Init

    init(userService: some UserServiceProtocol, musicService: some MusicServiceProtocol, storageService: some StorageServiceProtocol) {
        self.userService = userService
        self.musicService = musicService
        self.storageService = storageService
    }

    // MARK: - Load Profile

    /// Loads the user's profile and listening history.
    func loadProfile(userId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("loadProfile called with empty userId")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            user = try await userService.fetchUser(userId: userId)
            if let user {
                editDisplayName = user.displayName
                editBio = user.bio ?? ""
                editPronouns = user.pronouns ?? ""
                editMood = user.mood ?? ""
                editFavoriteSongName = user.favoriteSong?.name ?? ""
                editFavoriteSongArtist = user.favoriteSong?.artistName ?? ""
                editInstagram = user.socialLinks?.instagram ?? ""
                editSpotify = user.socialLinks?.spotify ?? ""
                editTwitter = user.socialLinks?.twitter ?? ""
                editFavoriteGenres = user.favoriteGenres
            }

            listeningHistory = try await userService.fetchListeningHistory(userId: userId, limit: 20)
            await buildOnRepeatSongs()

            // Load imported playlists
            await loadImportedPlaylists(userId: userId)

            // Auto-fetch Apple Music profile photo if user has none
            if user?.photoURL == nil {
                await fetchAndSetAppleMusicPhoto(userId: userId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Save Profile

    /// Saves the edited profile fields to Firestore.
    func saveProfile(userId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("saveProfile called with empty userId")
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            try await userService.updateDisplayName(userId: userId, displayName: editDisplayName)
            try await userService.updateBio(userId: userId, bio: editBio)
            try await userService.updateFavoriteGenres(userId: userId, genres: editFavoriteGenres)

            // Save pronouns (empty string → nil to delete the field)
            let pronouns = editPronouns.trimmingCharacters(in: .whitespacesAndNewlines)
            try await userService.updatePronouns(userId: userId, pronouns: pronouns.isEmpty ? nil : pronouns)

            // Save mood
            let mood = editMood.trimmingCharacters(in: .whitespacesAndNewlines)
            try await userService.updateMood(userId: userId, mood: mood.isEmpty ? nil : mood)

            // Save favorite song
            let songName = editFavoriteSongName.trimmingCharacters(in: .whitespacesAndNewlines)
            let songArtist = editFavoriteSongArtist.trimmingCharacters(in: .whitespacesAndNewlines)
            if !songName.isEmpty, !songArtist.isEmpty {
                let song = FavoriteSong(id: UUID().uuidString, name: songName, artistName: songArtist)
                try await userService.updateFavoriteSong(userId: userId, song: song)
            } else {
                try await userService.updateFavoriteSong(userId: userId, song: nil)
            }

            // Save social links
            let instagram = editInstagram.trimmingCharacters(in: .whitespacesAndNewlines)
            let spotify = editSpotify.trimmingCharacters(in: .whitespacesAndNewlines)
            let twitter = editTwitter.trimmingCharacters(in: .whitespacesAndNewlines)
            if instagram.isEmpty, spotify.isEmpty, twitter.isEmpty {
                try await userService.updateSocialLinks(userId: userId, links: nil)
            } else {
                let links = SocialLinks(
                    instagram: instagram.isEmpty ? nil : instagram,
                    spotify: spotify.isEmpty ? nil : spotify,
                    twitter: twitter.isEmpty ? nil : twitter
                )
                try await userService.updateSocialLinks(userId: userId, links: links)
            }

            // Refresh the local user
            user = try await userService.fetchUser(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }

    // MARK: - Profile Photo

    /// Uploads a user-selected photo to Firebase Storage and updates their profile.
    /// - Parameters:
    ///   - userId: The current user's ID.
    ///   - imageData: JPEG-compressed image data.
    func uploadProfilePhoto(userId: String, imageData: Data) async {
        guard !userId.isEmpty else {
            Log.user.error("uploadProfilePhoto called with empty userId")
            return
        }

        isUploadingPhoto = true
        errorMessage = nil

        do {
            let downloadURL = try await storageService.uploadProfilePhoto(imageData: imageData, userId: userId)
            try await userService.updatePhotoURL(userId: userId, photoURL: downloadURL)
            user = try await userService.fetchUser(userId: userId)
        } catch {
            Log.user.error("Failed to upload profile photo: \(error.localizedDescription)")
            errorMessage = String(localized: "Failed to upload photo. Please try again.")
        }

        isUploadingPhoto = false
    }

    /// Fetches the user's Apple Music social profile photo and saves the URL to Firestore.
    /// Does nothing if the user already has a photo URL set.
    func fetchAndSetAppleMusicPhoto(userId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("fetchAndSetAppleMusicPhoto called with empty userId")
            return
        }

        // Skip if user already has a photo
        guard user?.photoURL == nil else { return }

        isUploadingPhoto = true

        do {
            if let photoURL = try await musicService.fetchProfilePhotoURL(width: 400, height: 400) {
                try await userService.updatePhotoURL(userId: userId, photoURL: photoURL.absoluteString)
                user = try await userService.fetchUser(userId: userId)
            }
        } catch {
            Log.user.error("Failed to fetch Apple Music profile photo: \(error)")
            // Silently fail — this is a best-effort enhancement
        }

        isUploadingPhoto = false
    }

    // MARK: - On Repeat

    /// Aggregates listening history into top songs by play count and fetches
    /// missing artwork URLs from Apple Music.
    func buildOnRepeatSongs() async {
        // Group sessions by songId
        var grouped: [String: (sessions: [ListeningSession], totalSeconds: Int)] = [:]
        for session in listeningHistory {
            var entry = grouped[session.songId, default: (sessions: [], totalSeconds: 0)]
            entry.sessions.append(session)
            entry.totalSeconds += session.durationSeconds
            grouped[session.songId] = entry
        }

        // Sort by play count (descending), take top 5
        let top = grouped
            .sorted { $0.value.sessions.count > $1.value.sessions.count }
            .prefix(5)

        // Collect song IDs that need artwork
        let missingArtworkIds = top.compactMap { songId, entry -> String? in
            entry.sessions.first?.artworkURL == nil ? songId : nil
        }

        // Batch-fetch missing artwork from Apple Music
        var artworkMap: [String: String] = [:]
        if !missingArtworkIds.isEmpty {
            do {
                artworkMap = try await musicService.fetchArtworkURLs(for: missingArtworkIds, width: 300, height: 300)
            } catch {
                Log.music.error("Failed to fetch artwork URLs for On Repeat: \(error.localizedDescription)")
            }
        }

        // Build final array
        onRepeatSongs = top.map { songId, entry in
            let representative = entry.sessions
                .sorted { $0.listenedAt > $1.listenedAt }
                .first!
            let artwork = representative.artworkURL ?? artworkMap[songId]
            return OnRepeatSong(
                id: songId,
                songName: representative.songName,
                artistName: representative.artistName,
                genre: representative.genre,
                artworkURL: artwork,
                playCount: entry.sessions.count,
                totalSeconds: entry.totalSeconds,
                lastPlayed: representative.listenedAt
            )
        }
    }

    // MARK: - Auto-Populate Top Artists

    /// Fetches the user's recently played songs and extracts unique artists,
    /// then looks up each artist's artwork via MusicKit.
    func autoPopulateTopArtists(userId: String) async {
        do {
            let songs = try await musicService.fetchRecentlyPlayed()
            var seenArtists: Set<String> = []
            var topArtists: [TopArtist] = []

            for song in songs {
                let artistName = song.artistName
                if !seenArtists.contains(artistName) {
                    seenArtists.insert(artistName)

                    // Use the song's artwork as a fallback, look up artist artwork
                    let songArtworkURL = song.artwork?.url(width: 200, height: 200)?.absoluteString
                    var artworkURL = songArtworkURL

                    // Try to get the actual artist photo from MusicKit
                    do {
                        let artists = try await musicService.searchArtists(query: artistName, limit: 1)
                        if let artist = artists.first,
                           let artistArt = artist.artwork?.url(width: 200, height: 200) {
                            artworkURL = artistArt.absoluteString
                        }
                    } catch {
                        Log.music.error("Failed to look up artist artwork for \(artistName): \(error.localizedDescription)")
                    }

                    topArtists.append(TopArtist(
                        id: song.id.rawValue,
                        name: artistName,
                        artworkURL: artworkURL
                    ))
                }
                if topArtists.count >= Constants.Matching.maxTopArtists { break }
            }

            try await userService.updateTopArtists(userId: userId, artists: topArtists)
            user = try await userService.fetchUser(userId: userId)
        } catch {
            Log.user.error("Failed to auto-populate top artists: \(error.localizedDescription)")
        }
    }

    // MARK: - Listen for Profile Changes

    /// Starts listening for real-time profile updates.
    func listenForProfileChanges(userId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("listenForProfileChanges called with empty userId")
            return
        }
        for await updatedUser in userService.userChanges(userId: userId) {
            guard !Task.isCancelled else { return }
            user = updatedUser
        }
    }

    // MARK: - Imported Playlists

    /// Loads the user's imported playlists from Firestore.
    func loadImportedPlaylists(userId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("loadImportedPlaylists called with empty userId")
            return
        }

        do {
            importedPlaylists = try await userService.fetchImportedPlaylists(userId: userId)
        } catch {
            Log.user.error("Failed to load imported playlists: \(error.localizedDescription)")
        }
    }

    /// Saves an imported playlist to Firestore and adds it to the local array.
    /// Uses an optimistic update: the playlist is added locally first so the
    /// UI reflects the change immediately, then persisted to Firestore.
    func saveImportedPlaylist(userId: String, playlist: ImportedPlaylist) async {
        guard !userId.isEmpty else {
            Log.user.error("saveImportedPlaylist called with empty userId")
            return
        }

        // Optimistic local insert — UI updates immediately
        if !importedPlaylists.contains(where: { $0.id == playlist.id }) {
            importedPlaylists.insert(playlist, at: 0)
        }

        do {
            try await userService.saveImportedPlaylist(userId: userId, playlist: playlist)
        } catch {
            // Roll back on failure
            importedPlaylists.removeAll { $0.id == playlist.id }
            Log.user.error("Failed to save imported playlist: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes an imported playlist from Firestore and removes it from the local array.
    func deleteImportedPlaylist(userId: String, playlistId: String) async {
        guard !userId.isEmpty else {
            Log.user.error("deleteImportedPlaylist called with empty userId")
            return
        }

        do {
            try await userService.deleteImportedPlaylist(userId: userId, playlistId: playlistId)
            importedPlaylists.removeAll { $0.id == playlistId }
        } catch {
            Log.user.error("Failed to delete imported playlist: \(error.localizedDescription)")
        }
    }
}
