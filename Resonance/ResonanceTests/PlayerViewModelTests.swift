//  PlayerViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - PlayerViewModelTests

@MainActor
@Suite("PlayerViewModel Tests")
struct PlayerViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        musicService: MockMusicService = MockMusicService(),
        userService: MockUserService = MockUserService()
    ) -> (viewModel: PlayerViewModel, music: MockMusicService, user: MockUserService) {
        let vm = PlayerViewModel(musicService: musicService, userService: userService)
        return (vm, musicService, userService)
    }

    // MARK: - Pause

    @Test("pause calls musicService.pause and sets isPlaying false")
    func pause() {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)
        vm.isPlaying = true

        vm.pause()

        #expect(vm.isPlaying == false)
        #expect(music.pauseCallCount == 1)
    }

    // MARK: - Resume

    @Test("resume calls musicService.resume and sets isPlaying true on success")
    func resumeSuccess() async {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.resume()

        #expect(vm.isPlaying == true)
        #expect(music.resumeCallCount == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test("resume sets errorMessage on failure")
    func resumeFailure() async {
        let music = MockMusicService()
        music.stubbedResumeError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Resume failed"])

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.resume()

        #expect(vm.errorMessage == "Resume failed")
    }

    // MARK: - Toggle Playback

    @Test("togglePlayback pauses when playing")
    func togglePlaybackPause() async {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)
        vm.isPlaying = true

        await vm.togglePlayback()

        #expect(vm.isPlaying == false)
        #expect(music.pauseCallCount == 1)
    }

    @Test("togglePlayback resumes when paused")
    func togglePlaybackResume() async {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)
        vm.isPlaying = false

        await vm.togglePlayback()

        #expect(vm.isPlaying == true)
        #expect(music.resumeCallCount == 1)
    }

    // MARK: - Skip

    @Test("skipToNext calls musicService.skipToNext")
    func skipToNext() async {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.skipToNext()

        #expect(music.skipToNextCallCount == 1)
        #expect(vm.errorMessage == nil)
    }

    @Test("skipToNext sets errorMessage on failure")
    func skipToNextFailure() async {
        let music = MockMusicService()
        music.stubbedSkipToNextError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Skip failed"])

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.skipToNext()

        #expect(vm.errorMessage == "Skip failed")
    }

    @Test("skipToPrevious calls musicService.skipToPrevious")
    func skipToPrevious() async {
        let music = MockMusicService()

        let (vm, _, _) = makeSUT(musicService: music)

        await vm.skipToPrevious()

        #expect(music.skipToPreviousCallCount == 1)
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Now Playing Observation

    @Test("startObservingNowPlaying starts observation task")
    func startObservingNowPlaying() async {
        let music = MockMusicService()
        music.isAnyPlayerPlaying = true

        let (vm, _, _) = makeSUT(musicService: music)

        vm.startObservingNowPlaying()

        // Wait for one polling cycle
        try? await Task.sleep(for: .milliseconds(100))

        #expect(vm.isPlaying == true)

        vm.stopObservingNowPlaying()
    }

    @Test("stopObservingNowPlaying cancels observation")
    func stopObservingNowPlaying() {
        let (vm, _, _) = makeSUT()

        vm.startObservingNowPlaying()
        vm.stopObservingNowPlaying()

        // Should not crash or have side effects
        #expect(vm.errorMessage == nil)
    }

    // MARK: - Save Listening Session

    @Test("saveListeningSession does nothing when no current song")
    func saveListeningSessionNoSong() async {
        let user = MockUserService()

        let (vm, _, _) = makeSUT(userService: user)
        vm.currentSong = nil

        await vm.saveListeningSession(userId: "user-1")

        #expect(user.saveListeningSessionCallCount == 0)
    }
}
