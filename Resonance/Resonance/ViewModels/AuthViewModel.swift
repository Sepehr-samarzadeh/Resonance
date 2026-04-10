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

    private let authService = AuthService()
    private let userService = UserService()

    // MARK: - Init

    init() {
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

    /// Prepares the Apple Sign-In request with a nonce.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) async {
        let (_, hashedNonce) = await authService.prepareAppleSignIn()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
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
        for await firebaseUser in await authService.authStateChanges() {
            if let firebaseUser {
                isSignedIn = true
                await loadUserProfile(userId: firebaseUser.uid)
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
