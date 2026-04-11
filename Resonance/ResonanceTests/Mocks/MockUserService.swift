//  MockUserService.swift
//  ResonanceTests

import Foundation
@testable import Resonance

final class MockUserService: UserServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var fetchUserCallCount = 0
    var fetchUserLastUserId: String?
    var updateProfileCallCount = 0
    var updateDisplayNameCallCount = 0
    var updateBioCallCount = 0
    var updatePhotoURLCallCount = 0
    var updateFavoriteGenresCallCount = 0
    var updateTopArtistsCallCount = 0
    var updateCurrentlyListeningCallCount = 0
    var saveListeningSessionCallCount = 0
    var fetchListeningHistoryCallCount = 0
    var userChangesCallCount = 0

    // MARK: - Stubbed Results

    var stubbedFetchUserResult: Result<ResonanceUser?, Error> = .success(nil)
    var stubbedUpdateProfileError: Error?
    var stubbedUpdateDisplayNameError: Error?
    var stubbedUpdateBioError: Error?
    var stubbedUpdatePhotoURLError: Error?
    var stubbedUpdateFavoriteGenresError: Error?
    var stubbedUpdateTopArtistsError: Error?
    var stubbedUpdateCurrentlyListeningError: Error?
    var stubbedSaveListeningSessionError: Error?
    var stubbedFetchListeningHistoryResult: Result<[ListeningSession], Error> = .success([])
    var stubbedUserChanges: [ResonanceUser?] = []

    // MARK: - Captured Values

    var capturedDisplayName: String?
    var capturedBio: String?
    var capturedPhotoURL: String?
    var capturedGenres: [String]?
    var capturedTopArtists: [TopArtist]?
    var capturedCurrentlyListening: CurrentlyListening??

    // MARK: - Protocol Methods

    func fetchUser(userId: String) async throws -> ResonanceUser? {
        fetchUserCallCount += 1
        fetchUserLastUserId = userId
        return try stubbedFetchUserResult.get()
    }

    func updateProfile(_ user: ResonanceUser) async throws {
        updateProfileCallCount += 1
        if let error = stubbedUpdateProfileError { throw error }
    }

    func updateDisplayName(userId: String, displayName: String) async throws {
        updateDisplayNameCallCount += 1
        capturedDisplayName = displayName
        if let error = stubbedUpdateDisplayNameError { throw error }
    }

    func updateBio(userId: String, bio: String) async throws {
        updateBioCallCount += 1
        capturedBio = bio
        if let error = stubbedUpdateBioError { throw error }
    }

    func updatePhotoURL(userId: String, photoURL: String) async throws {
        updatePhotoURLCallCount += 1
        capturedPhotoURL = photoURL
        if let error = stubbedUpdatePhotoURLError { throw error }
    }

    func updateFavoriteGenres(userId: String, genres: [String]) async throws {
        updateFavoriteGenresCallCount += 1
        capturedGenres = genres
        if let error = stubbedUpdateFavoriteGenresError { throw error }
    }

    func updateTopArtists(userId: String, artists: [TopArtist]) async throws {
        updateTopArtistsCallCount += 1
        capturedTopArtists = artists
        if let error = stubbedUpdateTopArtistsError { throw error }
    }

    func updateCurrentlyListening(userId: String, listening: CurrentlyListening?) async throws {
        updateCurrentlyListeningCallCount += 1
        capturedCurrentlyListening = listening
        if let error = stubbedUpdateCurrentlyListeningError { throw error }
    }

    func saveListeningSession(userId: String, session: ListeningSession) async throws {
        saveListeningSessionCallCount += 1
        if let error = stubbedSaveListeningSessionError { throw error }
    }

    func fetchListeningHistory(userId: String, limit: Int) async throws -> [ListeningSession] {
        fetchListeningHistoryCallCount += 1
        return try stubbedFetchListeningHistoryResult.get()
    }

    func userChanges(userId: String) -> AsyncStream<ResonanceUser?> {
        userChangesCallCount += 1
        return AsyncStream { continuation in
            for user in stubbedUserChanges {
                continuation.yield(user)
            }
            continuation.finish()
        }
    }
}
