//  DiscoveryServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - DiscoveryServiceProtocol

/// Protocol defining the interface for user discovery and friend request services.
protocol DiscoveryServiceProtocol: Sendable {

    // MARK: - Discovery Queries

    /// Fetches users currently listening to the same song (excluding self and blocked).
    func fetchUsersListeningToSong(songId: String, currentUserId: String, blockedUserIds: [String]) async throws -> [ResonanceUser]

    /// Fetches users currently listening to the same artist (excluding self and blocked).
    func fetchUsersListeningToArtist(artistName: String, currentUserId: String, blockedUserIds: [String]) async throws -> [ResonanceUser]

    /// Fetches users with high music taste similarity, sorted by score descending.
    func fetchSimilarUsers(userId: String, limit: Int, blockedUserIds: [String]) async throws -> [(user: ResonanceUser, score: Double)]

    // MARK: - Friend Requests

    /// Sends a friend request from one user to another.
    func sendFriendRequest(from senderId: String, to receiverId: String) async throws

    /// Accepts a friend request and creates a Match document for chat.
    func acceptFriendRequest(requestId: String) async throws -> Match

    /// Declines a friend request.
    func declineFriendRequest(requestId: String) async throws

    /// Cancels a sent friend request.
    func cancelFriendRequest(requestId: String) async throws

    /// Fetches incoming friend requests for a user.
    func fetchIncomingRequests(userId: String) async throws -> [FriendRequest]

    /// Fetches outgoing friend requests from a user.
    func fetchOutgoingRequests(userId: String) async throws -> [FriendRequest]

    /// Returns an `AsyncStream` of incoming request changes for real-time updates.
    func incomingRequestChanges(userId: String) -> AsyncStream<[FriendRequest]>

    /// Checks the request status between two users (in either direction).
    func findExistingRequest(userId1: String, userId2: String) async throws -> FriendRequest?
}
