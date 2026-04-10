//  MatchViewModel.swift
//  Resonance

import Foundation

// MARK: - MatchViewModel

@MainActor
@Observable
final class MatchViewModel {

    // MARK: - Properties

    var matches: [Match] = []
    var isLoading = false
    var errorMessage: String?

    private let matchService = MatchService()
    private let userService = UserService()

    // MARK: - Load Matches

    /// Fetches all matches for the given user.
    func loadMatches(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            matches = try await matchService.fetchMatches(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Listen for Matches

    /// Starts listening for real-time match updates.
    func listenForMatches(userId: String) async {
        for await updatedMatches in await matchService.matchChanges(userId: userId) {
            matches = updatedMatches
        }
    }

    // MARK: - Check for Real-Time Match

    /// Checks if any other users are listening to the same song and creates a match.
    func checkForRealtimeMatch(userId: String, songId: String, songName: String, artistName: String) async {
        do {
            let matchedUserIds = try await matchService.findUsersListeningToSong(songId: songId, currentUserId: userId)

            for matchedUserId in matchedUserIds {
                let triggerSong = TriggerSong(id: songId, name: songName, artistName: artistName)
                try await matchService.createRealtimeMatch(userId1: userId, userId2: matchedUserId, song: triggerSong)
            }
        } catch {
            print("MatchViewModel: Failed to check for realtime match — \(error.localizedDescription)")
        }
    }

    // MARK: - Get Other User

    /// Returns the other user's profile in a match.
    func getOtherUser(match: Match, currentUserId: String) async -> ResonanceUser? {
        guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else {
            return nil
        }
        return try? await userService.fetchUser(userId: otherUserId)
    }
}
