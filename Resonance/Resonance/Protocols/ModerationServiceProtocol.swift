//  ModerationServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - ModerationServiceProtocol

/// Protocol defining the interface for user reporting and blocking services.
/// Used by ViewModels for testability via dependency injection.
protocol ModerationServiceProtocol: Sendable {

    /// Submits a report of objectionable content to Firestore.
    func submitReport(_ report: Report) async throws

    /// Blocks a user by adding their ID to the current user's `blockedUserIds`.
    func blockUser(currentUserId: String, blockedUserId: String) async throws

    /// Unblocks a previously blocked user.
    func unblockUser(currentUserId: String, blockedUserId: String) async throws

    /// Fetches the list of blocked user IDs for a given user.
    func fetchBlockedUserIds(for userId: String) async throws -> [String]

    /// Fetches basic profile info for a list of user IDs (for the blocked users list).
    func fetchUsers(ids: [String]) async throws -> [ResonanceUser]
}
