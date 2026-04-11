//  ProfileViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - ProfileViewModelTests

@MainActor
@Suite("ProfileViewModel Tests")
struct ProfileViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        userService: MockUserService = MockUserService(),
        musicService: MockMusicService = MockMusicService(),
        storageService: MockStorageService = MockStorageService()
    ) -> (viewModel: ProfileViewModel, user: MockUserService, music: MockMusicService, storage: MockStorageService) {
        let vm = ProfileViewModel(
            userService: userService,
            musicService: musicService,
            storageService: storageService
        )
        return (vm, userService, musicService, storageService)
    }

    // MARK: - Load Profile

    @Test("loadProfile fetches user and listening history on success")
    func loadProfileSuccess() async {
        let testUser = TestData.makeUser(displayName: "Alice", bio: "Music lover")
        let testHistory = [TestData.makeListeningSession(), TestData.makeListeningSession()]

        let user = MockUserService()
        user.stubbedFetchUserResult = .success(testUser)
        user.stubbedFetchListeningHistoryResult = .success(testHistory)

        let (vm, _, _, _) = makeSUT(userService: user)

        await vm.loadProfile(userId: "user-1")

        #expect(vm.user?.displayName == "Alice")
        #expect(vm.editDisplayName == "Alice")
        #expect(vm.editBio == "Music lover")
        #expect(vm.editFavoriteGenres == ["Pop", "Rock"])
        #expect(vm.listeningHistory.count == 2)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadProfile sets errorMessage on failure")
    func loadProfileFailure() async {
        let user = MockUserService()
        user.stubbedFetchUserResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"]))

        let (vm, _, _, _) = makeSUT(userService: user)

        await vm.loadProfile(userId: "user-1")

        #expect(vm.user == nil)
        #expect(vm.errorMessage == "Fetch failed")
        #expect(vm.isLoading == false)
    }

    // MARK: - Save Profile

    @Test("saveProfile updates display name, bio, and genres")
    func saveProfileSuccess() async {
        let user = MockUserService()
        let updatedUser = TestData.makeUser(displayName: "Bob", bio: "Updated bio", favoriteGenres: ["Jazz"])
        user.stubbedFetchUserResult = .success(updatedUser)

        let (vm, _, _, _) = makeSUT(userService: user)

        vm.editDisplayName = "Bob"
        vm.editBio = "Updated bio"
        vm.editFavoriteGenres = ["Jazz"]

        await vm.saveProfile(userId: "user-1")

        #expect(user.updateDisplayNameCallCount == 1)
        #expect(user.capturedDisplayName == "Bob")
        #expect(user.updateBioCallCount == 1)
        #expect(user.capturedBio == "Updated bio")
        #expect(user.updateFavoriteGenresCallCount == 1)
        #expect(user.capturedGenres == ["Jazz"])
        #expect(vm.isSaving == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("saveProfile sets errorMessage on failure")
    func saveProfileFailure() async {
        let user = MockUserService()
        user.stubbedUpdateDisplayNameError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])

        let (vm, _, _, _) = makeSUT(userService: user)

        vm.editDisplayName = "Bob"

        await vm.saveProfile(userId: "user-1")

        #expect(vm.errorMessage == "Save failed")
        #expect(vm.isSaving == false)
    }

    // MARK: - Upload Profile Photo

    @Test("uploadProfilePhoto uploads image and updates photo URL")
    func uploadProfilePhotoSuccess() async {
        let storage = MockStorageService()
        storage.stubbedUploadProfilePhotoResult = .success("https://example.com/new-photo.jpg")

        let user = MockUserService()
        let updatedUser = TestData.makeUser(photoURL: "https://example.com/new-photo.jpg")
        user.stubbedFetchUserResult = .success(updatedUser)

        let (vm, _, _, _) = makeSUT(userService: user, storageService: storage)

        let imageData = Data([0x89, 0x50, 0x4E, 0x47]) // Fake PNG header
        await vm.uploadProfilePhoto(imageData: imageData, userId: "user-1")

        #expect(storage.uploadProfilePhotoCallCount == 1)
        #expect(user.updatePhotoURLCallCount == 1)
        #expect(user.capturedPhotoURL == "https://example.com/new-photo.jpg")
        #expect(vm.isUploadingPhoto == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("uploadProfilePhoto sets errorMessage on failure")
    func uploadProfilePhotoFailure() async {
        let storage = MockStorageService()
        storage.stubbedUploadProfilePhotoResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Upload failed"]))

        let (vm, _, _, _) = makeSUT(storageService: storage)

        await vm.uploadProfilePhoto(imageData: Data(), userId: "user-1")

        #expect(vm.errorMessage == "Upload failed")
        #expect(vm.isUploadingPhoto == false)
    }

    // MARK: - Listen for Profile Changes

    @Test("listenForProfileChanges updates user from stream")
    func listenForProfileChanges() async {
        let updatedUser = TestData.makeUser(displayName: "Updated Name")
        let user = MockUserService()
        user.stubbedUserChanges = [updatedUser]

        let (vm, _, _, _) = makeSUT(userService: user)

        await vm.listenForProfileChanges(userId: "user-1")

        #expect(vm.user?.displayName == "Updated Name")
    }

    // MARK: - Loading States

    @Test("loadProfile toggles isLoading")
    func loadProfileLoading() async {
        let user = MockUserService()
        user.stubbedFetchUserResult = .success(nil)
        user.stubbedFetchListeningHistoryResult = .success([])

        let (vm, _, _, _) = makeSUT(userService: user)

        #expect(vm.isLoading == false)

        await vm.loadProfile(userId: "user-1")

        #expect(vm.isLoading == false)
    }
}
