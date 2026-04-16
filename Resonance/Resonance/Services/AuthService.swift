//  AuthService.swift
//  Resonance

import Foundation
import AuthenticationServices
@preconcurrency import FirebaseAuth
@preconcurrency import FirebaseCore
@preconcurrency import FirebaseFirestore
import CryptoKit
import GoogleSignIn

// MARK: - AuthService

actor AuthService: AuthServiceProtocol {

    // MARK: - Properties

    /// Firestore instance — resolved lazily to ensure Firebase is configured first.
    private var db: Firestore {
        Firestore.firestore()
    }
    private var currentNonce: String?

    // MARK: - Current User

    /// Returns the currently authenticated Firebase user, if any.
    nonisolated var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }

    /// Returns the currently authenticated user's UID, if any.
    nonisolated var currentUserId: String? {
        currentUser?.uid
    }

    /// Returns whether a user is currently signed in.
    nonisolated var isSignedIn: Bool {
        currentUser != nil
    }

    // MARK: - Sign in with Apple

    /// Prepares a nonce for Sign in with Apple and returns both the raw and hashed versions.
    func prepareAppleSignIn() -> (nonce: String, hashedNonce: String) {
        let nonce = (try? randomNonceString()) ?? UUID().uuidString
        currentNonce = nonce
        let hashedNonce = sha256(nonce)
        return (nonce, hashedNonce)
    }

    /// Completes the Sign in with Apple flow using the authorization result.
    /// - Parameter authorization: The `ASAuthorization` returned by the system.
    /// - Returns: The authenticated `ResonanceUser`.
    @discardableResult
    func completeAppleSignIn(authorization: ASAuthorization) async throws -> ResonanceUser {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let nonce = currentNonce else {
            throw AuthError.missingNonce
        }

        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        let displayName = buildDisplayName(from: appleIDCredential.fullName) ?? firebaseUser.displayName ?? String(localized: "Anonymous")

        let resonanceUser = ResonanceUser(
            id: firebaseUser.uid,
            displayName: displayName,
            email: firebaseUser.email ?? "",
            photoURL: firebaseUser.photoURL?.absoluteString,
            bio: nil,
            pronouns: nil,
            mood: nil,
            favoriteSong: nil,
            socialLinks: nil,
            authProvider: .apple,
            favoriteGenres: [],
            topArtists: [],
            currentlyListening: nil,
            deviceToken: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await createOrUpdateUser(resonanceUser)
        return resonanceUser
    }

    // MARK: - Google Sign-In

    /// Completes Google Sign-In using an ID token and access token from the Google SDK.
    /// - Parameters:
    ///   - idToken: The Google ID token string.
    ///   - accessToken: The Google access token string.
    /// - Returns: The authenticated `ResonanceUser`.
    @discardableResult
    func completeGoogleSignIn(idToken: String, accessToken: String) async throws -> ResonanceUser {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        let resonanceUser = ResonanceUser(
            id: firebaseUser.uid,
            displayName: firebaseUser.displayName ?? String(localized: "Anonymous"),
            email: firebaseUser.email ?? "",
            photoURL: firebaseUser.photoURL?.absoluteString,
            bio: nil,
            pronouns: nil,
            mood: nil,
            favoriteSong: nil,
            socialLinks: nil,
            authProvider: .google,
            favoriteGenres: [],
            topArtists: [],
            currentlyListening: nil,
            deviceToken: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        try await createOrUpdateUser(resonanceUser)
        return resonanceUser
    }

    // MARK: - Google Sign-In (Presentation)

    /// Initiates the Google Sign-In flow by presenting the sign-in UI.
    /// Returns the ID token and access token on success.
    @MainActor
    func presentGoogleSignIn() async throws -> (idToken: String, accessToken: String) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown(String(localized: "Missing Firebase client ID."))
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.unknown(String(localized: "Unable to find root view controller."))
        }

        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthError.missingIdentityToken
        }
        let accessToken = signInResult.user.accessToken.tokenString
        return (idToken, accessToken)
    }

    // MARK: - Sign Out

    /// Signs out the current user from Firebase and Google.
    nonisolated func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Delete Account

    /// Deletes the currently authenticated user's Firebase Auth account.
    /// Throws if the user is not signed in or re-authentication is required.
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.unknown(String(localized: "No user is currently signed in."))
        }
        try await user.delete()
    }

    // MARK: - Auth State Listener

    /// Returns an `AsyncStream` that emits the current Firebase user's UID whenever auth state changes.
    /// Streams `nil` when no user is signed in.
    nonisolated func authStateChanges() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handle = Auth.auth().addStateDidChangeListener { @Sendable _, user in
                continuation.yield(user?.uid)
            }
            nonisolated(unsafe) let unsafeHandle = handle
            continuation.onTermination = { @Sendable _ in
                Auth.auth().removeStateDidChangeListener(unsafeHandle)
            }
        }
    }

    // MARK: - Private Helpers

    private func createOrUpdateUser(_ user: ResonanceUser) async throws {
        guard let userId = user.id else { return }

        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument()

        let dict = try encodeToDict(user)

        if snapshot.exists {
            try await docRef.setData(dict, merge: true)
        } else {
            try await docRef.setData(dict)
        }
    }

    private func buildDisplayName(from fullName: PersonNameComponents?) -> String? {
        guard let fullName else { return nil }
        var components: [String] = []
        if let givenName = fullName.givenName {
            components.append(givenName)
        }
        if let familyName = fullName.familyName {
            components.append(familyName)
        }
        return components.isEmpty ? nil : components.joined(separator: " ")
    }

    private func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            throw AuthError.unknown(String(localized: "Unable to generate secure nonce. Please try again."))
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - AuthError

enum AuthError: LocalizedError, Sendable {
    case invalidCredential
    case missingNonce
    case missingIdentityToken
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            String(localized: "Invalid credential received.")
        case .missingNonce:
            String(localized: "Authentication nonce is missing. Please try again.")
        case .missingIdentityToken:
            String(localized: "Unable to retrieve identity token.")
        case .unknown(let message):
            message
        }
    }
}
