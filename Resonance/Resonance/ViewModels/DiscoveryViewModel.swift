//  DiscoveryViewModel.swift
//  Resonance

import Foundation
import SwiftUI
import OSLog

// MARK: - DiscoveryViewModel

@MainActor
@Observable
final class DiscoveryViewModel {

    // MARK: - Properties

    /// Users currently listening to the same song as the current user.
    var listeningNowUsers: [ResonanceUser] = []

    /// Users with similar music taste, paired with their similarity score.
    var similarUsers: [(user: ResonanceUser, score: Double)] = []

    /// Incoming friend requests awaiting response.
    var incomingRequests: [FriendRequest] = []

    /// Outgoing pending friend requests (to show "Requested" state).
    var outgoingRequests: [FriendRequest] = []

    /// User profiles keyed by ID for request senders.
    var requestUserProfiles: [String: ResonanceUser] = [:]

    var isLoadingListeners = false
    var isLoadingSimilar = false
    var isLoadingRequests = false
    var errorMessage: String?

    /// Track IDs of users we've sent requests to (for optimistic UI).
    var sentRequestUserIds: Set<String> = []

    private let discoveryService: any DiscoveryServiceProtocol
    private let userService: any UserServiceProtocol
    private var requestListenerTask: Task<Void, Never>?

    // MARK: - Init

    init(discoveryService: some DiscoveryServiceProtocol, userService: some UserServiceProtocol) {
        self.discoveryService = discoveryService
        self.userService = userService
    }

    // MARK: - Load Listening Now

    /// Fetches users listening to the same song or artist.
    func loadListeningNow(songId: String?, artistName: String?, currentUserId: String) async {
        isLoadingListeners = true
        defer { isLoadingListeners = false }

        do {
            var users: [ResonanceUser] = []

            if let songId {
                users = try await discoveryService.fetchUsersListeningToSong(
                    songId: songId,
                    currentUserId: currentUserId
                )
            }

            // If no song matches, try artist
            if users.isEmpty, let artistName {
                users = try await discoveryService.fetchUsersListeningToArtist(
                    artistName: artistName,
                    currentUserId: currentUserId
                )
            }

            listeningNowUsers = users
        } catch {
            Log.discovery.error("Failed to load listening now: \(error.localizedDescription)")
            listeningNowUsers = []
        }
    }

    // MARK: - Load Similar Users

    /// Fetches users with similar music taste.
    func loadSimilarUsers(userId: String) async {
        isLoadingSimilar = true
        defer { isLoadingSimilar = false }

        do {
            similarUsers = try await discoveryService.fetchSimilarUsers(userId: userId, limit: 20)
        } catch {
            Log.discovery.error("Failed to load similar users: \(error.localizedDescription)")
            similarUsers = []
        }
    }

    // MARK: - Friend Requests

    /// Sends a friend request to another user.
    func sendRequest(to receiverId: String, from senderId: String) async {
        sentRequestUserIds.insert(receiverId)

        do {
            try await discoveryService.sendFriendRequest(from: senderId, to: receiverId)
            // Refresh outgoing requests
            outgoingRequests = try await discoveryService.fetchOutgoingRequests(userId: senderId)
        } catch {
            sentRequestUserIds.remove(receiverId)
            Log.discovery.error("Failed to send request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Accepts an incoming friend request.
    func acceptRequest(_ request: FriendRequest) async {
        guard let requestId = request.id else { return }

        do {
            _ = try await discoveryService.acceptFriendRequest(requestId: requestId)
            incomingRequests.removeAll { $0.id == requestId }
        } catch {
            Log.discovery.error("Failed to accept request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Declines an incoming friend request.
    func declineRequest(_ request: FriendRequest) async {
        guard let requestId = request.id else { return }

        do {
            try await discoveryService.declineFriendRequest(requestId: requestId)
            incomingRequests.removeAll { $0.id == requestId }
        } catch {
            Log.discovery.error("Failed to decline request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    /// Cancels an outgoing friend request.
    func cancelRequest(_ request: FriendRequest) async {
        guard let requestId = request.id else { return }

        do {
            try await discoveryService.cancelFriendRequest(requestId: requestId)
            outgoingRequests.removeAll { $0.id == requestId }
            sentRequestUserIds.remove(request.receiverId)
        } catch {
            Log.discovery.error("Failed to cancel request: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load Requests

    /// Loads both incoming and outgoing requests and fetches sender profiles.
    func loadRequests(userId: String) async {
        isLoadingRequests = true
        defer { isLoadingRequests = false }

        do {
            async let incomingTask = discoveryService.fetchIncomingRequests(userId: userId)
            async let outgoingTask = discoveryService.fetchOutgoingRequests(userId: userId)

            incomingRequests = try await incomingTask
            outgoingRequests = try await outgoingTask

            // Track outgoing request receiver IDs for UI state
            sentRequestUserIds = Set(outgoingRequests.map(\.receiverId))

            // Fetch profiles for incoming request senders
            for request in incomingRequests {
                if requestUserProfiles[request.senderId] == nil {
                    let profile = try? await userService.fetchUser(userId: request.senderId)
                    requestUserProfiles[request.senderId] = profile
                }
            }
        } catch {
            Log.discovery.error("Failed to load requests: \(error.localizedDescription)")
        }
    }

    // MARK: - Real-Time Request Listener

    /// Starts listening for incoming request changes in real time.
    func listenForIncomingRequests(userId: String) {
        requestListenerTask?.cancel()
        requestListenerTask = Task {
            for await requests in discoveryService.incomingRequestChanges(userId: userId) {
                guard !Task.isCancelled else { return }
                incomingRequests = requests

                // Fetch any new sender profiles
                for request in requests {
                    if requestUserProfiles[request.senderId] == nil {
                        let profile = try? await userService.fetchUser(userId: request.senderId)
                        requestUserProfiles[request.senderId] = profile
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Checks the relationship status with another user.
    func relationshipStatus(with userId: String) -> RelationshipStatus {
        if sentRequestUserIds.contains(userId) {
            return .requestSent
        }
        if incomingRequests.contains(where: { $0.senderId == userId }) {
            return .requestReceived
        }
        return .none
    }
}

// MARK: - RelationshipStatus

enum RelationshipStatus: Sendable {
    case none
    case requestSent
    case requestReceived
}
