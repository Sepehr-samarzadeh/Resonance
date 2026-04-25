//  MatchViewModel.swift
//  Resonance

import Foundation
import SwiftUI
import OSLog

// MARK: - MatchViewModel

@MainActor
@Observable
final class MatchViewModel {

    // MARK: - Properties

    var matches: [Match] = []
    var isLoading = false
    var isLoadingMore = false
    var hasMoreMatches = true
    var errorMessage: String?

    /// Blocked user IDs — matches involving these users are hidden.
    var blockedUserIds: [String] = []

    private let matchService: any MatchServiceProtocol
    private let userService: any UserServiceProtocol

    /// Number of matches to fetch per page.
    private let pageSize = 20

    // MARK: - Init

    init(matchService: some MatchServiceProtocol, userService: some UserServiceProtocol) {
        self.matchService = matchService
        self.userService = userService
    }

    // MARK: - Load Matches (paginated)

    /// Fetches the first page of matches for the given user.
    func loadMatches(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await matchService.fetchMatches(userId: userId, limit: pageSize, afterDate: nil)
            matches = filterBlocked(fetched)
            hasMoreMatches = fetched.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Loads the next page of matches using cursor-based pagination.
    func loadMoreMatches(userId: String) async {
        guard hasMoreMatches, !isLoadingMore else { return }

        isLoadingMore = true

        do {
            let cursor = matches.last?.createdAt
            let fetched = try await matchService.fetchMatches(userId: userId, limit: pageSize, afterDate: cursor)
            matches.append(contentsOf: filterBlocked(fetched))
            hasMoreMatches = fetched.count >= pageSize
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoadingMore = false
    }

    // MARK: - Listen for Matches

    /// Starts listening for real-time match updates.
    func listenForMatches(userId: String) async {
        for await updatedMatches in matchService.matchChanges(userId: userId) {
            guard !Task.isCancelled else { return }
            matches = filterBlocked(updatedMatches)
        }
    }

    // MARK: - Delete Match

    /// Deletes a match (conversation) and removes it from the local list.
    func deleteMatch(matchId: String) async {
        // Remove from local array first (inside an animation transaction)
        // so SwiftUI's List diffing stays consistent with the swipe-delete animation.
        withAnimation {
            matches.removeAll { $0.id == matchId }
        }

        do {
            try await matchService.deleteMatch(matchId: matchId)
        } catch {
            // Restore on failure — reload from server
            errorMessage = error.localizedDescription
            Log.match.error("Failed to delete match \(matchId): \(error.localizedDescription)")
        }
    }

    // MARK: - Check for Real-Time Match

    /// Checks if any other users are listening to the same song or artist and creates matches.
    /// Returns the first newly created match, or nil if no new match was created.
    @discardableResult
    func checkForRealtimeMatch(userId: String, songId: String, songName: String, artistName: String) async -> Match? {
        do {
            // Check by song
            let songMatchedUserIds = try await matchService.findUsersListeningToSong(songId: songId, currentUserId: userId)

            for matchedUserId in songMatchedUserIds {
                // Deduplicate: skip if a match already exists between these users
                let existingMatch = try await matchService.findExistingMatch(userId1: userId, userId2: matchedUserId)
                if existingMatch != nil { continue }

                let triggerSong = TriggerSong(id: songId, name: songName, artistName: artistName)
                let matchId = try await matchService.createRealtimeMatch(userId1: userId, userId2: matchedUserId, song: triggerSong)
                // Return the newly created match
                let newMatch = Match(
                    id: matchId,
                    userIds: [userId, matchedUserId],
                    matchType: .realtime,
                    triggerSong: triggerSong,
                    triggerArtist: nil,
                    similarityScore: nil,
                    createdAt: Date()
                )
                return newMatch
            }

            // Check by artist
            let artistMatchedUserIds = try await matchService.findUsersListeningToArtist(artistName: artistName, currentUserId: userId)

            for matchedUserId in artistMatchedUserIds {
                let existingMatch = try await matchService.findExistingMatch(userId1: userId, userId2: matchedUserId)
                if existingMatch != nil { continue }

                let triggerArtist = TriggerArtist(id: artistName, name: artistName)
                let matchId = try await matchService.createArtistMatch(userId1: userId, userId2: matchedUserId, artist: triggerArtist)
                let newMatch = Match(
                    id: matchId,
                    userIds: [userId, matchedUserId],
                    matchType: .realtime,
                    triggerSong: nil,
                    triggerArtist: triggerArtist,
                    similarityScore: nil,
                    createdAt: Date()
                )
                return newMatch
            }
        } catch {
            Log.match.error("Failed to check for realtime match: \(error.localizedDescription)")
        }

        return nil
    }

    // MARK: - Get Other User

    /// Returns the other user's profile in a match.
    func getOtherUser(match: Match, currentUserId: String) async -> ResonanceUser? {
        guard let otherUserId = match.userIds.first(where: { $0 != currentUserId }) else {
            return nil
        }
        do {
            return try await userService.fetchUser(userId: otherUserId)
        } catch {
            Log.user.error("Failed to fetch other user \(otherUserId): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Blocked Filtering

    /// Removes matches that involve any blocked user.
    private func filterBlocked(_ matches: [Match]) -> [Match] {
        guard !blockedUserIds.isEmpty else { return matches }
        let blocked = Set(blockedUserIds)
        return matches.filter { match in
            !match.userIds.contains { blocked.contains($0) }
        }
    }
}
