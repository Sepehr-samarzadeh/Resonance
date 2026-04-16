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
        let testUser = TestData.makeUser(
            displayName: "Alice",
            photoURL: "https://example.com/photo.jpg",
            bio: "Music lover",
            pronouns: "she/her",
            mood: "Vibing",
            favoriteSong: FavoriteSong(id: "s1", name: "Starboy", artistName: "The Weeknd"),
            socialLinks: SocialLinks(instagram: "alice_music", spotify: "alice123")
        )
        let testHistory = [TestData.makeListeningSession(), TestData.makeListeningSession()]

        let user = MockUserService()
        user.stubbedFetchUserResult = .success(testUser)
        user.stubbedFetchListeningHistoryResult = .success(testHistory)

        let (vm, _, _, _) = makeSUT(userService: user)

        await vm.loadProfile(userId: "user-1")

        #expect(vm.user?.displayName == "Alice")
        #expect(vm.editDisplayName == "Alice")
        #expect(vm.editBio == "Music lover")
        #expect(vm.editPronouns == "she/her")
        #expect(vm.editMood == "Vibing")
        #expect(vm.editFavoriteSongName == "Starboy")
        #expect(vm.editFavoriteSongArtist == "The Weeknd")
        #expect(vm.editInstagram == "alice_music")
        #expect(vm.editSpotify == "alice123")
        #expect(vm.editTwitter == "")
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

    @Test("saveProfile updates display name, bio, genres, and new fields")
    func saveProfileSuccess() async {
        let user = MockUserService()
        let updatedUser = TestData.makeUser(displayName: "Bob", bio: "Updated bio", favoriteGenres: ["Jazz"])
        user.stubbedFetchUserResult = .success(updatedUser)

        let (vm, _, _, _) = makeSUT(userService: user)

        vm.editDisplayName = "Bob"
        vm.editBio = "Updated bio"
        vm.editFavoriteGenres = ["Jazz"]
        vm.editPronouns = "he/him"
        vm.editMood = "Chill"
        vm.editFavoriteSongName = "Blinding Lights"
        vm.editFavoriteSongArtist = "The Weeknd"
        vm.editInstagram = "bob_music"
        vm.editSpotify = ""
        vm.editTwitter = "bob_x"

        await vm.saveProfile(userId: "user-1")

        #expect(user.updateDisplayNameCallCount == 1)
        #expect(user.capturedDisplayName == "Bob")
        #expect(user.updateBioCallCount == 1)
        #expect(user.capturedBio == "Updated bio")
        #expect(user.updateFavoriteGenresCallCount == 1)
        #expect(user.capturedGenres == ["Jazz"])
        #expect(user.updatePronounsCallCount == 1)
        #expect(user.capturedPronouns == "he/him")
        #expect(user.updateMoodCallCount == 1)
        #expect(user.capturedMood == "Chill")
        #expect(user.updateFavoriteSongCallCount == 1)
        #expect(user.capturedFavoriteSong??.name == "Blinding Lights")
        #expect(user.updateSocialLinksCallCount == 1)
        #expect(user.capturedSocialLinks??.instagram == "bob_music")
        #expect(user.capturedSocialLinks??.spotify == nil)
        #expect(user.capturedSocialLinks??.twitter == "bob_x")
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

    // MARK: - Apple Music Profile Photo

    @Test("fetchAndSetAppleMusicPhoto sets photoURL when available")
    func fetchAppleMusicPhotoSuccess() async {
        let music = MockMusicService()
        music.stubbedProfilePhotoURL = URL(string: "https://is1-ssl.mzstatic.com/image/photo.jpg")

        let user = MockUserService()
        let updatedUser = TestData.makeUser(photoURL: "https://is1-ssl.mzstatic.com/image/photo.jpg")
        user.stubbedFetchUserResult = .success(updatedUser)

        let (vm, _, _, _) = makeSUT(userService: user, musicService: music)
        // User starts with no photo
        vm.user = TestData.makeUser(photoURL: nil)

        await vm.fetchAndSetAppleMusicPhoto(userId: "user-1")

        #expect(music.fetchProfilePhotoURLCallCount == 1)
        #expect(user.updatePhotoURLCallCount == 1)
        #expect(user.capturedPhotoURL == "https://is1-ssl.mzstatic.com/image/photo.jpg")
        #expect(vm.isUploadingPhoto == false)
    }

    @Test("fetchAndSetAppleMusicPhoto skips when user already has photo")
    func fetchAppleMusicPhotoSkipsExisting() async {
        let music = MockMusicService()
        music.stubbedProfilePhotoURL = URL(string: "https://example.com/new.jpg")

        let (vm, user, _, _) = makeSUT(musicService: music)
        // User already has a photo
        vm.user = TestData.makeUser(photoURL: "https://example.com/existing.jpg")

        await vm.fetchAndSetAppleMusicPhoto(userId: "user-1")

        // Should not have attempted to fetch or update
        #expect(music.fetchProfilePhotoURLCallCount == 0)
        #expect(user.updatePhotoURLCallCount == 0)
    }

    @Test("fetchAndSetAppleMusicPhoto handles nil URL gracefully")
    func fetchAppleMusicPhotoNil() async {
        let music = MockMusicService()
        music.stubbedProfilePhotoURL = nil

        let (vm, user, _, _) = makeSUT(musicService: music)
        vm.user = TestData.makeUser(photoURL: nil)

        await vm.fetchAndSetAppleMusicPhoto(userId: "user-1")

        #expect(music.fetchProfilePhotoURLCallCount == 1)
        #expect(user.updatePhotoURLCallCount == 0)
        #expect(vm.isUploadingPhoto == false)
        #expect(vm.errorMessage == nil)
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

    // MARK: - Save Profile — Empty Optional Fields

    @Test("saveProfile clears optional fields when empty")
    func saveProfileClearsOptionalFields() async {
        let user = MockUserService()
        user.stubbedFetchUserResult = .success(TestData.makeUser())

        let (vm, _, _, _) = makeSUT(userService: user)

        vm.editDisplayName = "Test"
        vm.editBio = ""
        vm.editPronouns = ""
        vm.editMood = "  "
        vm.editFavoriteSongName = ""
        vm.editFavoriteSongArtist = ""
        vm.editInstagram = ""
        vm.editSpotify = ""
        vm.editTwitter = ""
        vm.editFavoriteGenres = []

        await vm.saveProfile(userId: "user-1")

        // Pronouns and mood should be nil (empty/whitespace → delete)
        #expect(user.updatePronounsCallCount == 1)
        #expect(user.capturedPronouns == .some(nil))
        #expect(user.updateMoodCallCount == 1)
        #expect(user.capturedMood == .some(nil))
        // Favorite song should be nil (both fields empty)
        #expect(user.updateFavoriteSongCallCount == 1)
        #expect(user.capturedFavoriteSong == .some(nil))
        // Social links should be nil (all empty)
        #expect(user.updateSocialLinksCallCount == 1)
        #expect(user.capturedSocialLinks == .some(nil))
    }

    // MARK: - Upload Profile Photo

    @Test("uploadProfilePhoto uploads data and updates photoURL")
    func uploadProfilePhotoSuccess() async {
        let storage = MockStorageService()
        storage.stubbedUploadProfilePhotoResult = .success("https://storage.example.com/photo.jpg")

        let user = MockUserService()
        let updatedUser = TestData.makeUser(photoURL: "https://storage.example.com/photo.jpg")
        user.stubbedFetchUserResult = .success(updatedUser)

        let (vm, _, _, _) = makeSUT(userService: user, storageService: storage)
        let testData = Data([0x00, 0x01, 0x02])

        await vm.uploadProfilePhoto(userId: "user-1", imageData: testData)

        #expect(storage.uploadProfilePhotoCallCount == 1)
        #expect(storage.capturedImageData == testData)
        #expect(storage.capturedUserId == "user-1")
        #expect(user.updatePhotoURLCallCount == 1)
        #expect(user.capturedPhotoURL == "https://storage.example.com/photo.jpg")
        #expect(vm.user?.photoURL == "https://storage.example.com/photo.jpg")
        #expect(vm.isUploadingPhoto == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("uploadProfilePhoto sets error on failure")
    func uploadProfilePhotoFailure() async {
        let storage = MockStorageService()
        storage.stubbedUploadProfilePhotoResult = .failure(NSError(domain: "test", code: 1))

        let (vm, _, _, _) = makeSUT(storageService: storage)

        await vm.uploadProfilePhoto(userId: "user-1", imageData: Data([0xFF]))

        #expect(storage.uploadProfilePhotoCallCount == 1)
        #expect(vm.errorMessage != nil)
        #expect(vm.isUploadingPhoto == false)
    }
}
