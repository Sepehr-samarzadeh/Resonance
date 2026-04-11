//  MockAuthService.swift
//  ResonanceTests

import Foundation
import AuthenticationServices
@testable import Resonance

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {

    // MARK: - Stubbed Properties

    var stubbedIsSignedIn = false
    var stubbedCurrentUserId: String?

    var isSignedIn: Bool { stubbedIsSignedIn }
    var currentUserId: String? { stubbedCurrentUserId }

    // MARK: - Call Tracking

    var prepareAppleSignInCallCount = 0
    var completeAppleSignInCallCount = 0
    var completeGoogleSignInCallCount = 0
    var presentGoogleSignInCallCount = 0
    var signOutCallCount = 0
    var authStateChangesCallCount = 0

    // MARK: - Stubbed Results

    var stubbedAppleSignInNonce: (nonce: String, hashedNonce: String) = ("raw-nonce", "hashed-nonce")
    var stubbedCompleteAppleSignInResult: Result<ResonanceUser, Error> = .failure(NSError(domain: "test", code: -1))
    var stubbedGoogleSignInTokens: (idToken: String, accessToken: String) = ("id-token", "access-token")
    var stubbedCompleteGoogleSignInResult: Result<ResonanceUser, Error> = .failure(NSError(domain: "test", code: -1))
    var stubbedPresentGoogleSignInResult: Result<(idToken: String, accessToken: String), Error> = .success(("id-token", "access-token"))
    var stubbedSignOutError: Error?
    var stubbedAuthStateChanges: [String?] = []

    // MARK: - Protocol Methods

    func prepareAppleSignIn() async -> (nonce: String, hashedNonce: String) {
        prepareAppleSignInCallCount += 1
        return stubbedAppleSignInNonce
    }

    @discardableResult
    func completeAppleSignIn(authorization: ASAuthorization) async throws -> ResonanceUser {
        completeAppleSignInCallCount += 1
        return try stubbedCompleteAppleSignInResult.get()
    }

    @discardableResult
    func completeGoogleSignIn(idToken: String, accessToken: String) async throws -> ResonanceUser {
        completeGoogleSignInCallCount += 1
        return try stubbedCompleteGoogleSignInResult.get()
    }

    @MainActor
    func presentGoogleSignIn() async throws -> (idToken: String, accessToken: String) {
        presentGoogleSignInCallCount += 1
        return try stubbedPresentGoogleSignInResult.get()
    }

    func signOut() throws {
        signOutCallCount += 1
        if let error = stubbedSignOutError {
            throw error
        }
    }

    func authStateChanges() -> AsyncStream<String?> {
        authStateChangesCallCount += 1
        return AsyncStream { continuation in
            for uid in stubbedAuthStateChanges {
                continuation.yield(uid)
            }
            continuation.finish()
        }
    }
}
