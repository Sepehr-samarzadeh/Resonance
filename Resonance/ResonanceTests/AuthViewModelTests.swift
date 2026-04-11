//  AuthViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - AuthViewModelTests

@MainActor
@Suite("AuthViewModel Tests")
struct AuthViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        authService: MockAuthService = MockAuthService(),
        userService: MockUserService = MockUserService(),
        notificationService: MockNotificationService = MockNotificationService()
    ) -> (viewModel: AuthViewModel, auth: MockAuthService, user: MockUserService, notification: MockNotificationService) {
        let vm = AuthViewModel(
            authService: authService,
            userService: userService,
            notificationService: notificationService
        )
        return (vm, authService, userService, notificationService)
    }

    // MARK: - Check Existing Session

    @Test("checkExistingSession sets isSignedIn when user is signed in")
    func checkExistingSessionSignedIn() async {
        let auth = MockAuthService()
        auth.stubbedIsSignedIn = true
        auth.stubbedCurrentUserId = "user-1"

        let user = MockUserService()
        user.stubbedFetchUserResult = .success(TestData.makeUser())

        let (vm, _, _, _) = makeSUT(authService: auth, userService: user)

        #expect(vm.isSignedIn == true)
    }

    @Test("checkExistingSession sets isSignedIn false when not signed in")
    func checkExistingSessionNotSignedIn() {
        let auth = MockAuthService()
        auth.stubbedIsSignedIn = false

        let (vm, _, _, _) = makeSUT(authService: auth)

        #expect(vm.isSignedIn == false)
        #expect(vm.currentUser == nil)
    }

    // MARK: - Prepare Nonce

    @Test("prepareCachedNonce calls authService.prepareAppleSignIn")
    func prepareCachedNonce() async {
        let (vm, auth, _, _) = makeSUT()

        await vm.prepareCachedNonce()

        #expect(auth.prepareAppleSignInCallCount == 1)
    }

    // MARK: - Google Sign-In

    @Test("signInWithGoogle sets isSignedIn on success")
    func signInWithGoogleSuccess() async {
        let testUser = TestData.makeUser(authProvider: .google)
        let auth = MockAuthService()
        auth.stubbedPresentGoogleSignInResult = .success(("id-token", "access-token"))
        auth.stubbedCompleteGoogleSignInResult = .success(testUser)

        let (vm, _, _, _) = makeSUT(authService: auth)

        await vm.signInWithGoogle()

        #expect(vm.isSignedIn == true)
        #expect(vm.currentUser?.displayName == testUser.displayName)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    @Test("signInWithGoogle sets errorMessage on failure")
    func signInWithGoogleFailure() async {
        let auth = MockAuthService()
        auth.stubbedPresentGoogleSignInResult = .failure(NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "Google failed"]))

        let (vm, _, _, _) = makeSUT(authService: auth)

        await vm.signInWithGoogle()

        #expect(vm.isSignedIn == false)
        #expect(vm.errorMessage == "Google failed")
        #expect(vm.isLoading == false)
    }

    // MARK: - Sign Out

    @Test("signOut clears user and sets isSignedIn to false")
    func signOutSuccess() async {
        let testUser = TestData.makeUser()
        let auth = MockAuthService()
        auth.stubbedIsSignedIn = true
        auth.stubbedCurrentUserId = testUser.id

        let user = MockUserService()
        user.stubbedFetchUserResult = .success(testUser)

        let (vm, _, _, notification) = makeSUT(authService: auth, userService: user)

        // Wait for initial profile load
        try? await Task.sleep(for: .milliseconds(100))

        vm.signOut()

        #expect(vm.isSignedIn == false)
        #expect(vm.currentUser == nil)
        #expect(auth.signOutCallCount == 1)
    }

    @Test("signOut sets errorMessage when signOut throws")
    func signOutFailure() {
        let auth = MockAuthService()
        auth.stubbedSignOutError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign out error"])

        let (vm, _, _, _) = makeSUT(authService: auth)

        vm.signOut()

        #expect(vm.errorMessage == "Sign out error")
    }

    // MARK: - Listen for Auth Changes

    @Test("listenForAuthChanges updates state when user signs in")
    func listenForAuthChangesSignIn() async {
        let testUser = TestData.makeUser(id: "user-abc")
        let auth = MockAuthService()
        auth.stubbedAuthStateChanges = ["user-abc"]

        let user = MockUserService()
        user.stubbedFetchUserResult = .success(testUser)

        let (vm, _, _, _) = makeSUT(authService: auth, userService: user)

        await vm.listenForAuthChanges()

        #expect(vm.isSignedIn == true)
        #expect(vm.currentUser?.id == "user-abc")
    }

    @Test("listenForAuthChanges clears state when user signs out")
    func listenForAuthChangesSignOut() async {
        let auth = MockAuthService()
        auth.stubbedAuthStateChanges = [nil]

        let (vm, _, _, _) = makeSUT(authService: auth)

        await vm.listenForAuthChanges()

        #expect(vm.isSignedIn == false)
        #expect(vm.currentUser == nil)
    }

    // MARK: - Loading State

    @Test("signInWithGoogle sets isLoading during operation")
    func signInWithGoogleLoading() async {
        let auth = MockAuthService()
        auth.stubbedPresentGoogleSignInResult = .success(("id", "access"))
        auth.stubbedCompleteGoogleSignInResult = .success(TestData.makeUser())

        let (vm, _, _, _) = makeSUT(authService: auth)

        #expect(vm.isLoading == false)

        await vm.signInWithGoogle()

        #expect(vm.isLoading == false)
    }
}
