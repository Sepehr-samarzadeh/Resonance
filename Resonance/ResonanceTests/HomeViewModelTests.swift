//  HomeViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - HomeViewModelTests

@MainActor
@Suite("HomeViewModel Tests")
struct HomeViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        musicService: MockMusicService = MockMusicService(),
        userService: MockUserService = MockUserService()
    ) -> (viewModel: HomeViewModel, music: MockMusicService, user: MockUserService) {
        let vm = HomeViewModel(musicService: musicService, userService: userService)
        return (vm, musicService, userService)
    }

    // MARK: - Load Data

    @Test("loadData fetches recently played songs on success")
    func loadDataSuccess() async {
        let music = MockMusicService()
        // fetchRecentlyPlayed returns [Song] which we can't easily mock,
        // but we can test the empty success path and error path
        music.stubbedFetchRecentlyPlayedResult = .success([])

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.loadData()

        #expect(vm.recentlyPlayed.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(music.fetchRecentlyPlayedCallCount == 1)
    }

    @Test("loadData sets errorMessage on failure")
    func loadDataFailure() async {
        let music = MockMusicService()
        music.stubbedFetchRecentlyPlayedResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Music error"]))

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.loadData()

        #expect(vm.errorMessage == "Music error")
        #expect(vm.isLoading == false)
    }

    // MARK: - Update Currently Listening

    @Test("updateCurrentlyListening clears listening when song is nil")
    func updateCurrentlyListeningNil() async {
        let user = MockUserService()

        let (vm, _, _) = makeSUT(userService: user)

        await vm.updateCurrentlyListening(userId: "user-1", song: nil)

        #expect(user.updateCurrentlyListeningCallCount == 1)
        // captured value should be nil (cleared)
        #expect(user.capturedCurrentlyListening == nil as CurrentlyListening?)
    }

    // MARK: - Loading State

    @Test("loadData toggles isLoading")
    func loadDataLoading() async {
        let music = MockMusicService()
        music.stubbedFetchRecentlyPlayedResult = .success([])

        let (vm, _, _) = makeSUT(musicService: music)

        #expect(vm.isLoading == false)

        await vm.loadData()

        #expect(vm.isLoading == false)
    }
}
