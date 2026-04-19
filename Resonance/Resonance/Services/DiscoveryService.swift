//  DiscoveryService.swift
//  Resonance

import Foundation
import OSLog
@preconcurrency import FirebaseFirestore
@preconcurrency import FirebaseFunctions

// MARK: - DiscoveryService

private nonisolated(unsafe) let discoveryLog = Logger(subsystem: "com.resonance", category: "discovery")

actor DiscoveryService: DiscoveryServiceProtocol {

    // MARK: - Properties

    private var db: Firestore { Firestore.firestore() }
    private var functions: Functions { Functions.functions() }
    private let requestsCollection = "friendRequests"

    // MARK: - Discovery Queries

    /// Fetches full user objects currently listening to the same song.
    func fetchUsersListeningToSong(songId: String, currentUserId: String) async throws -> [ResonanceUser] {
        let snapshot = try await db.collection("users")
            .whereField("currentlyListening.songId", isEqualTo: songId)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> ResonanceUser? in
            guard doc.documentID != currentUserId else { return nil }
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(ResonanceUser.self, from: dict)
        }
    }

    /// Fetches full user objects currently listening to the same artist.
    func fetchUsersListeningToArtist(artistName: String, currentUserId: String) async throws -> [ResonanceUser] {
        let snapshot = try await db.collection("users")
            .whereField("currentlyListening.artistName", isEqualTo: artistName)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> ResonanceUser? in
            guard doc.documentID != currentUserId else { return nil }
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(ResonanceUser.self, from: dict)
        }
    }

    /// Fetches users with similar music taste, returning (user, score) pairs.
    func fetchSimilarUsers(userId: String, limit: Int) async throws -> [(user: ResonanceUser, score: Double)] {
        // Fetch recent active users to compare against
        let snapshot = try await db.collection("users")
            .order(by: "updatedAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        let candidates = snapshot.documents.compactMap { doc -> ResonanceUser? in
            guard doc.documentID != userId else { return nil }
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(ResonanceUser.self, from: dict)
        }

        // Calculate similarity for each candidate
        var results: [(user: ResonanceUser, score: Double)] = []

        for candidate in candidates {
            guard let candidateId = candidate.id else { continue }

            // Skip users we already have a match or request with
            let existingMatch = try await findExistingMatch(userId1: userId, userId2: candidateId)
            let existingRequest = try await findExistingRequest(userId1: userId, userId2: candidateId)
            if existingMatch != nil || existingRequest != nil { continue }

            let score = try await calculateSimilarity(userId1: userId, userId2: candidateId)
            if score >= 0.2 {
                results.append((user: candidate, score: score))
            }
        }

        // Sort by score descending and take top results
        return results
            .sorted { $0.score > $1.score }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Friend Requests

    /// Sends a friend request. Prevents duplicates.
    func sendFriendRequest(from senderId: String, to receiverId: String) async throws {
        // Check for existing request in either direction
        if let existing = try await findExistingRequest(userId1: senderId, userId2: receiverId) {
            if existing.status == .pending {
                discoveryLog.info("Friend request already exists between \(senderId) and \(receiverId)")
                return
            }
            if existing.status == .declined {
                // Allow re-requesting after a decline — update the existing doc
                guard let requestId = existing.id else { return }
                try await db.collection(requestsCollection).document(requestId).updateData([
                    "senderId": senderId,
                    "receiverId": receiverId,
                    "status": RequestStatus.pending.rawValue,
                    "updatedAt": FieldValue.serverTimestamp()
                ])
                return
            }
        }

        let request = FriendRequest(
            senderId: senderId,
            receiverId: receiverId,
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )
        let dict = try encodeToDict(request)
        try await db.collection(requestsCollection).addDocument(data: dict)
    }

    /// Accepts a friend request and creates a discovery Match for chat.
    func acceptFriendRequest(requestId: String) async throws -> Match {
        let doc = try await db.collection(requestsCollection).document(requestId).getDocument()
        guard var dict = doc.data() else {
            throw DiscoveryError.requestNotFound
        }
        dict["id"] = doc.documentID
        guard let request = decodeFromDictOptional(FriendRequest.self, from: dict) else {
            throw DiscoveryError.requestNotFound
        }

        // Update status to accepted
        try await db.collection(requestsCollection).document(requestId).updateData([
            "status": RequestStatus.accepted.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])

        // Create a match via Cloud Function so the existing chat system works
        let matchData: [String: Any] = [
            "userIds": [request.senderId, request.receiverId],
            "matchType": "discovery",
        ]
        let result = try await functions.httpsCallable("createMatch").call(matchData)
        guard let response = result.data as? [String: Any],
              let matchId = response["matchId"] as? String else {
            throw DiscoveryError.requestNotFound
        }

        var createdMatch = Match(
            userIds: [request.senderId, request.receiverId],
            matchType: .discovery,
            triggerSong: nil,
            triggerArtist: nil,
            similarityScore: nil,
            createdAt: Date()
        )
        createdMatch.id = matchId
        return createdMatch
    }

    /// Declines a friend request.
    func declineFriendRequest(requestId: String) async throws {
        try await db.collection(requestsCollection).document(requestId).updateData([
            "status": RequestStatus.declined.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }

    /// Cancels a sent friend request by deleting it.
    func cancelFriendRequest(requestId: String) async throws {
        try await db.collection(requestsCollection).document(requestId).delete()
    }

    /// Fetches incoming pending requests for a user.
    func fetchIncomingRequests(userId: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection(requestsCollection)
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(FriendRequest.self, from: dict)
        }
    }

    /// Fetches outgoing pending requests from a user.
    func fetchOutgoingRequests(userId: String) async throws -> [FriendRequest] {
        let snapshot = try await db.collection(requestsCollection)
            .whereField("senderId", isEqualTo: userId)
            .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            var dict = doc.data()
            dict["id"] = doc.documentID
            return decodeFromDictOptional(FriendRequest.self, from: dict)
        }
    }

    /// Real-time listener for incoming requests.
    nonisolated func incomingRequestChanges(userId: String) -> AsyncStream<[FriendRequest]> {
        let db = Firestore.firestore()
        let collection = "friendRequests"
        return AsyncStream { continuation in
            let listener = db.collection(collection)
                .whereField("receiverId", isEqualTo: userId)
                .whereField("status", isEqualTo: RequestStatus.pending.rawValue)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        discoveryLog.error("Error listening to requests: \(error.localizedDescription)")
                        return
                    }
                    let requests = snapshot?.documents.compactMap { doc -> FriendRequest? in
                        var dict = doc.data()
                        dict["id"] = doc.documentID
                        return decodeFromDictOptional(FriendRequest.self, from: dict)
                    } ?? []
                    continuation.yield(requests)
                }
            continuation.onTermination = { @Sendable _ in
                listener.remove()
            }
        }
    }

    /// Finds an existing request between two users in either direction.
    func findExistingRequest(userId1: String, userId2: String) async throws -> FriendRequest? {
        // Check userId1 -> userId2
        let snapshot1 = try await db.collection(requestsCollection)
            .whereField("senderId", isEqualTo: userId1)
            .whereField("receiverId", isEqualTo: userId2)
            .getDocuments()

        if let doc = snapshot1.documents.first {
            var dict = doc.data()
            dict["id"] = doc.documentID
            if let request = decodeFromDictOptional(FriendRequest.self, from: dict) {
                return request
            }
        }

        // Check userId2 -> userId1
        let snapshot2 = try await db.collection(requestsCollection)
            .whereField("senderId", isEqualTo: userId2)
            .whereField("receiverId", isEqualTo: userId1)
            .getDocuments()

        if let doc = snapshot2.documents.first {
            var dict = doc.data()
            dict["id"] = doc.documentID
            if let request = decodeFromDictOptional(FriendRequest.self, from: dict) {
                return request
            }
        }

        return nil
    }

    // MARK: - Similarity (reuses MatchService logic)

    /// Calculates similarity between two users. Same algorithm as MatchService.
    private func calculateSimilarity(userId1: String, userId2: String) async throws -> Double {
        async let profile1Task = fetchTasteProfile(userId: userId1)
        async let profile2Task = fetchTasteProfile(userId: userId2)
        async let history1Task = fetchListeningArtists(userId: userId1)
        async let history2Task = fetchListeningArtists(userId: userId2)

        let profile1 = try await profile1Task
        let profile2 = try await profile2Task
        let history1 = try await history1Task
        let history2 = try await history2Task

        let genreScore = Self.jaccardSimilarity(
            Set(profile1?.selectedGenres.map { $0.lowercased() } ?? []),
            Set(profile2?.selectedGenres.map { $0.lowercased() } ?? [])
        )

        let artistNames1 = Self.buildArtistNameSet(from: profile1)
        let artistNames2 = Self.buildArtistNameSet(from: profile2)
        let tasteArtistScore = Self.jaccardSimilarity(artistNames1, artistNames2)

        let historyScore = Self.jaccardSimilarity(Set(history1), Set(history2))

        let hasTasteData = (profile1 != nil && profile2 != nil)
            && (!artistNames1.isEmpty || !artistNames2.isEmpty
                || !(profile1?.selectedGenres.isEmpty ?? true)
                || !(profile2?.selectedGenres.isEmpty ?? true))
        let hasHistoryData = !history1.isEmpty && !history2.isEmpty

        switch (hasTasteData, hasHistoryData) {
        case (true, true):
            return genreScore * 0.3 + tasteArtistScore * 0.3 + historyScore * 0.4
        case (true, false):
            return genreScore * 0.5 + tasteArtistScore * 0.5
        case (false, true):
            return historyScore
        case (false, false):
            return 0.0
        }
    }

    // MARK: - Private Helpers

    private func findExistingMatch(userId1: String, userId2: String) async throws -> Match? {
        let snapshot = try await db.collection("matches")
            .whereField("userIds", arrayContains: userId1)
            .getDocuments()

        return snapshot.documents.compactMap { doc -> Match? in
            var dict = doc.data()
            dict["id"] = doc.documentID
            guard let match = decodeFromDictOptional(Match.self, from: dict) else { return nil }
            return match.userIds.contains(userId2) ? match : nil
        }.first
    }

    private func fetchTasteProfile(userId: String) async throws -> TasteProfile? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = snapshot.data(),
              let profileData = data["tasteProfile"] else { return nil }
        let json = try JSONSerialization.data(withJSONObject: profileData)
        return try JSONDecoder().decode(TasteProfile.self, from: json)
    }

    private func fetchListeningArtists(userId: String) async throws -> [String] {
        let snapshot = try await db.collection("listeningHistory")
            .document(userId)
            .collection("sessions")
            .order(by: "listenedAt", descending: true)
            .limit(to: 100)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            (doc.data()["artistName"] as? String)?.lowercased()
        }
    }

    private nonisolated static func jaccardSimilarity(_ set1: Set<String>, _ set2: Set<String>) -> Double {
        guard !set1.isEmpty || !set2.isEmpty else { return 0.0 }
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }

    private nonisolated static func buildArtistNameSet(from profile: TasteProfile?) -> Set<String> {
        guard let profile else { return [] }
        var names = Set(profile.libraryArtistNames)
        for artist in profile.selectedArtists {
            names.insert(artist.name.lowercased())
        }
        return names
    }
}

// MARK: - DiscoveryError

enum DiscoveryError: LocalizedError, Sendable {
    case requestNotFound
    case alreadyRequested

    var errorDescription: String? {
        switch self {
        case .requestNotFound:
            String(localized: "Friend request not found.")
        case .alreadyRequested:
            String(localized: "A friend request already exists.")
        }
    }
}
