//  AuthServiceProtocol.swift
//  Resonance

import Foundation
import AuthenticationServices

// MARK: - AuthServiceProtocol

/// Protocol defining the interface for authentication services.
/// Used by `AuthViewModel` for testability via dependency injection.
protocol AuthServiceProtocol: Sendable {

    /// Returns whether a user is currently signed in.
    var isSignedIn: Bool { get }

    /// Returns the currently authenticated user's UID, if any.
    var currentUserId: String? { get }

    /// Prepares a nonce for Sign in with Apple and returns both the raw and hashed versions.
    func prepareAppleSignIn() async -> (nonce: String, hashedNonce: String)

    /// Completes the Sign in with Apple flow using the authorization result.
    @discardableResult
    func completeAppleSignIn(authorization: ASAuthorization) async throws -> ResonanceUser

    /// Completes Google Sign-In using an ID token and access token from the Google SDK.
    @discardableResult
    func completeGoogleSignIn(idToken: String, accessToken: String) async throws -> ResonanceUser

    /// Initiates the Google Sign-In flow by presenting the sign-in UI.
    @MainActor
    func presentGoogleSignIn() async throws -> (idToken: String, accessToken: String)

    /// Signs out the current user from Firebase and Google.
    func signOut() throws

    /// Deletes the currently authenticated user's Firebase Auth account.
    /// The user may need to re-authenticate if the session is stale.
    func deleteAccount() async throws

    /// Returns an `AsyncStream` that emits the current Firebase user's UID whenever auth state changes.
    func authStateChanges() -> AsyncStream<String?>
}
