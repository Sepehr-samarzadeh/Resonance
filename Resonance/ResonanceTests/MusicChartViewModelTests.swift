//  MusicChartViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - MusicChartViewModelTests

@MainActor
@Suite("MusicChartViewModel Tests")
struct MusicChartViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        musicService: MockMusicService = MockMusicService()
    ) -> (viewModel: MusicChartViewModel, music: MockMusicService) {
        let vm = MusicChartViewModel(musicService: musicService)
        return (vm, musicService)
    }

    // MARK: - Fetch Charts

    @Test("fetchCharts fetches top songs on success")
    func fetchChartsSuccess() async {
        let music = MockMusicService()
        // MusicCatalogChart<Song> can't be easily constructed, so test empty success
        music.stubbedFetchTopSongsResult = .success([])

        let (vm, _) = makeSUT(musicService: music)

        await vm.fetchCharts()

        #expect(vm.songCharts.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
        #expect(music.fetchTopSongsCallCount == 1)
    }

    @Test("fetchCharts sets errorMessage on failure")
    func fetchChartsFailure() async {
        let music = MockMusicService()
        music.stubbedFetchTopSongsResult = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Charts error"]))

        let (vm, _) = makeSUT(musicService: music)

        await vm.fetchCharts()

        #expect(vm.songCharts.isEmpty)
        #expect(vm.errorMessage == "Charts error")
        #expect(vm.isLoading == false)
    }

    // MARK: - Loading State

    @Test("fetchCharts toggles isLoading")
    func fetchChartsLoading() async {
        let music = MockMusicService()
        music.stubbedFetchTopSongsResult = .success([])

        let (vm, _) = makeSUT(musicService: music)

        #expect(vm.isLoading == false)

        await vm.fetchCharts()

        #expect(vm.isLoading == false)
    }

    // MARK: - Initial State

    @Test("initial state is empty")
    func initialState() {
        let (vm, _) = makeSUT()

        #expect(vm.songCharts.isEmpty)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }
}
