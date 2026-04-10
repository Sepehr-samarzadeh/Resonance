//  AuthViewModel.swift
//  Resonance

import Foundation
import AuthenticationServices

// MARK: - AuthViewModel

@MainActor
@Observable
final class AuthViewModel {

    // MARK: - Properties

    var currentUser: ResonanceUser?
    var isSignedIn = false
    var isLoading = false
    var errorMessage: String?

    private let authService: AuthService
    private let userService: UserService
    private let notificationService: NotificationService

    /// Pre-cached nonce pair for Apple Sign-In.
    /// Generated before the sign-in sheet appears.
    private var cachedNonce: (nonce: String, hashedNonce: String)?

    // MARK: - Init

    init(authService: AuthService, userService: UserService, notificationService: NotificationService) {
        self.authService = authService
        self.userService = userService
        self.notificationService = notificationService
        checkExistingSession()
    }

    // MARK: - Session Check

    /// Checks if a user is already signed in and loads their profile.
    func checkExistingSession() {
        guard authService.isSignedIn, let uid = authService.currentUserId else {
            isSignedIn = false
            return
        }
        isSignedIn = true
        Task {
            await loadUserProfile(userId: uid)
        }
    }

    // MARK: - Sign in with Apple

    /// Pre-caches a nonce for Apple Sign-In. Call this before presenting
    /// the `SignInWithAppleButton` so the nonce is ready synchronously.
    func prepareCachedNonce() async {
        cachedNonce = await authService.prepareAppleSignIn()
    }

    /// Configures the Apple Sign-In request with the pre-cached nonce.
    /// This is called synchronously from `SignInWithAppleButton`'s `onRequest`.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        request.nonce = cachedNonce?.hashedNonce
    }

    /// Handles the result of Sign in with Apple.
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let authorization):
            do {
                let user = try await authService.completeAppleSignIn(authorization: authorization)
                currentUser = user
                isSignedIn = true
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Google Sign-In

    /// Initiates Google Sign-In flow via AuthService.
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
            let tokens = try await authService.presentGoogleSignIn()
            let user = try await authService.completeGoogleSignIn(
                idToken: tokens.idToken,
                accessToken: tokens.accessToken
            )
            currentUser = user
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign Out

    /// Signs out the current user and clears device token.
    func signOut() {
        let userId = currentUser?.id
        do {
            try authService.signOut()
            currentUser = nil
            isSignedIn = false

            // Remove device token in background
            if let userId {
                Task {
                    try? await notificationService.removeDeviceToken(forUserId: userId)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Listen for Auth Changes

    /// Starts listening for Firebase auth state changes.
    func listenForAuthChanges() async {
        for await userId in authService.authStateChanges() {
            if let userId {
                isSignedIn = true
                await loadUserProfile(userId: userId)
            } else {
                isSignedIn = false
                currentUser = nil
            }
        }
    }

    // MARK: - Private

    private func loadUserProfile(userId: String) async {
        do {
            currentUser = try await userService.fetchUser(userId: userId)
        } catch {
            print("AuthViewModel: Failed to load user profile — \(error.localizedDescription)")
        }
    }
}
