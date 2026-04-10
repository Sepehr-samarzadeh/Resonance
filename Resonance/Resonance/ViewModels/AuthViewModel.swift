//  AuthViewModel.swift
//  Resonance

import Foundation
import AuthenticationServices
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

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

    /// Pre-cached nonce pair for Apple Sign-In.
    /// Generated synchronously before the sign-in sheet appears.
    private var cachedNonce: (nonce: String, hashedNonce: String)?

    // MARK: - Init

    init(authService: AuthService, userService: UserService) {
        self.authService = authService
        self.userService = userService
        checkExistingSession()
    }

    // MARK: - Session Check

    /// Checks if a user is already signed in and loads their profile.
    func checkExistingSession() {
        guard let firebaseUser = Auth.auth().currentUser else {
            isSignedIn = false
            return
        }
        isSignedIn = true
        Task {
            await loadUserProfile(userId: firebaseUser.uid)
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
        if cachedNonce == nil {
            // Fallback: generate synchronously if not pre-cached.
            // This is safe because prepareAppleSignIn on AuthService is actor-isolated
            // but we pre-cache it in .task {} to avoid this path.
            request.requestedScopes = [.fullName, .email]
            return
        }
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

    /// Initiates Google Sign-In flow.
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        do {
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

            let user = try await authService.completeGoogleSignIn(idToken: idToken, accessToken: accessToken)
            currentUser = user
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Sign Out

    /// Signs out the current user.
    func signOut() {
        do {
            try authService.signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isSignedIn = false
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
