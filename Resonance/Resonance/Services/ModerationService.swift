//  ModerationService.swift
//  Resonance

import Foundation
import OSLog
@preconcurrency import FirebaseFirestore

// MARK: - ModerationService

private nonisolated(unsafe) let moderationLog = Logger(subsystem: "com.resonance", category: "moderation")

actor ModerationService: ModerationServiceProtocol {

    // MARK: - Properties

    private var db: Firestore { Firestore.firestore() }
    private let reportsCollection = "reports"

    // MARK: - Submit Report

    /// Writes a report document to the `reports` collection.
    /// Clients can create but not read reports (enforced by Firestore rules).
    func submitReport(_ report: Report) async throws {
        let dict = try encodeToDict(report)
        try await db.collection(reportsCollection).addDocument(data: dict)
        moderationLog.info("Report submitted by \(report.reporterId) against \(report.reportedUserId)")
    }

    // MARK: - Block User

    /// Adds `blockedUserId` to the current user's `blockedUserIds` array in the private subcollection.
    func blockUser(currentUserId: String, blockedUserId: String) async throws {
        try await db.collection("users").document(currentUserId)
            .collection("private").document("profile")
            .updateData([
                "blockedUserIds": FieldValue.arrayUnion([blockedUserId])
            ])
        moderationLog.info("User \(currentUserId) blocked \(blockedUserId)")
    }

    // MARK: - Unblock User

    /// Removes `blockedUserId` from the current user's `blockedUserIds` array in the private subcollection.
    func unblockUser(currentUserId: String, blockedUserId: String) async throws {
        try await db.collection("users").document(currentUserId)
            .collection("private").document("profile")
            .updateData([
                "blockedUserIds": FieldValue.arrayRemove([blockedUserId])
            ])
        moderationLog.info("User \(currentUserId) unblocked \(blockedUserId)")
    }

    // MARK: - Fetch Blocked User IDs

    /// Reads the current user's `blockedUserIds` from the private subcollection.
    func fetchBlockedUserIds(for userId: String) async throws -> [String] {
        let doc = try await db.collection("users").document(userId)
            .collection("private").document("profile")
            .getDocument()
        guard let data = doc.data() else { return [] }
        return data["blockedUserIds"] as? [String] ?? []
    }

    // MARK: - Fetch Users by IDs

    /// Fetches user profiles for a list of IDs (used for blocked users list).
    func fetchUsers(ids: [String]) async throws -> [ResonanceUser] {
        guard !ids.isEmpty else { return [] }

        // Firestore `in` queries support up to 30 values per batch.
        var users: [ResonanceUser] = []
        let batches = stride(from: 0, to: ids.count, by: 30).map {
            Array(ids[$0..<min($0 + 30, ids.count)])
        }
        for batch in batches {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: batch)
                .getDocuments()

            let batchUsers = snapshot.documents.compactMap { doc -> ResonanceUser? in
                var dict = doc.data()
                dict["id"] = doc.documentID
                return decodeFromDictOptional(ResonanceUser.self, from: dict)
            }
            users.append(contentsOf: batchUsers)
        }
        return users
    }
}
