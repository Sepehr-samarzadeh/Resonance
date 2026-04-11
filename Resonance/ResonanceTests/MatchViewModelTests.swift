//  MatchViewModelTests.swift
//  ResonanceTests

import Testing
import Foundation
@testable import Resonance

// MARK: - MatchViewModelTests

@MainActor
@Suite("MatchViewModel Tests")
struct MatchViewModelTests {

    // MARK: - Helpers

    private func makeSUT(
        matchService: MockMatchService = MockMatchService(),
        userService: MockUserService = MockUserService()
    ) -> (viewModel: MatchViewModel, match: MockMatchService, user: MockUserService) {
        let vm = MatchViewModel(matchService: matchService, userService: userService)
        return (vm, matchService, userService)
    }

    // MARK: - Load Matches

    @Test("loadMatches populates matches on success")
    func loadMatchesSuccess() async {
        let match = MockMatchService()
        let testMatches = [
            TestData.makeMatch(id: "m1"),
            TestData.makeMatch(id: "m2"),
        ]
        match.stubbedFetchMatchesPaginated = .success(testMatches)

        let (vm, _, _) = makeSUT(matchService: match)

        await vm.loadMatches(userId: "user-1")

        #expect(vm.matches.count == 2)
        #expect(vm.matches[0].id == "m1")
        #expect(vm.matches[1].id == "m2")
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("loadMatches sets errorMessage on failure")
    func loadMatchesFailure() async {
        let match = MockMatchService()
        match.stubbedFetchMatchesPaginated = .failure(NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))

        let (vm, _, _) = makeSUT(matchService: match)

        await vm.loadMatches(userId: "user-1")

        #expect(vm.matches.isEmpty)
        #expect(vm.errorMessage == "Network error")
        #expect(vm.isLoading == false)
    }

    // MARK: - Listen for Matches

    @Test("listenForMatches updates matches from stream")
    func listenForMatches() async {
        let match = MockMatchService()
        let testMatches = [TestData.makeMatch(id: "m1")]
        match.stubbedMatchChanges = [testMatches]

        let (vm, _, _) = makeSUT(matchService: match)

        await vm.listenForMatches(userId: "user-1")

        #expect(vm.matches.count == 1)
        #expect(vm.matches[0].id == "m1")
    }

    // MARK: - Check for Realtime Match (Song)

    @Test("checkForRealtimeMatch creates match when song match found and no existing match")
    func checkForRealtimeMatchSongSuccess() async {
        let match = MockMatchService()
        match.stubbedFindUsersListeningToSong = .success(["user-2"])
        match.stubbedFindExistingMatch = .success(nil)
        match.stubbedCreateRealtimeMatch = .success("new-match-id")

        let (vm, _, _) = makeSUT(matchService: match)

        let result = await vm.checkForRealtimeMatch(
            userId: "user-1",
            songId: "song-1",
            songName: "Test Song",
            artistName: "Test Artist"
        )

        #expect(result != nil)
        #expect(result?.id == "new-match-id")
        #expect(result?.matchType == .realtime)
        #expect(result?.triggerSong?.name == "Test Song")
        #expect(match.createRealtimeMatchCallCount == 1)
    }

    @Test("checkForRealtimeMatch skips when existing match found")
    func checkForRealtimeMatchExistingMatch() async {
        let match = MockMatchService()
        match.stubbedFindUsersListeningToSong = .success(["user-2"])
        match.stubbedFindExistingMatch = .success(TestData.makeMatch())
        // No song listeners, so also check artist path (empty)
        match.stubbedFindUsersListeningToArtist = .success([])

        let (vm, _, _) = makeSUT(matchService: match)

        let result = await vm.checkForRealtimeMatch(
            userId: "user-1",
            songId: "song-1",
            songName: "Test Song",
            artistName: "Test Artist"
        )

        #expect(result == nil)
        #expect(match.createRealtimeMatchCallCount == 0)
    }

    // MARK: - Check for Realtime Match (Artist)

    @Test("checkForRealtimeMatch creates artist match when no song match but artist match found")
    func checkForRealtimeMatchArtistSuccess() async {
        let match = MockMatchService()
        match.stubbedFindUsersListeningToSong = .success([]) // No song matches
        match.stubbedFindUsersListeningToArtist = .success(["user-3"])
        match.stubbedFindExistingMatch = .success(nil)
        match.stubbedCreateArtistMatch = .success("artist-match-id")

        let (vm, _, _) = makeSUT(matchService: match)

        let result = await vm.checkForRealtimeMatch(
            userId: "user-1",
            songId: "song-1",
            songName: "Test Song",
            artistName: "Test Artist"
        )

        #expect(result != nil)
        #expect(result?.id == "artist-match-id")
        #expect(result?.triggerArtist?.name == "Test Artist")
        #expect(result?.triggerSong == nil)
        #expect(match.createArtistMatchCallCount == 1)
    }

    @Test("checkForRealtimeMatch returns nil when no matches found")
    func checkForRealtimeMatchNoMatches() async {
        let match = MockMatchService()
        match.stubbedFindUsersListeningToSong = .success([])
        match.stubbedFindUsersListeningToArtist = .success([])

        let (vm, _, _) = makeSUT(matchService: match)

        let result = await vm.checkForRealtimeMatch(
            userId: "user-1",
            songId: "song-1",
            songName: "Test Song",
            artistName: "Test Artist"
        )

        #expect(result == nil)
    }

    // MARK: - Get Other User

    @Test("getOtherUser returns the other user in a match")
    func getOtherUser() async {
        let otherUser = TestData.makeUser(id: "user-2", displayName: "Other User")
        let user = MockUserService()
        user.stubbedFetchUserResult = .success(otherUser)

        let (vm, _, _) = makeSUT(userService: user)

        let testMatch = TestData.makeMatch(userIds: ["user-1", "user-2"])
        let result = await vm.getOtherUser(match: testMatch, currentUserId: "user-1")

        #expect(result?.id == "user-2")
        #expect(result?.displayName == "Other User")
        #expect(user.fetchUserLastUserId == "user-2")
    }

    @Test("getOtherUser returns nil for single-user match")
    func getOtherUserSingleUser() async {
        let (vm, _, _) = makeSUT()

        let testMatch = TestData.makeMatch(userIds: ["user-1"])
        let result = await vm.getOtherUser(match: testMatch, currentUserId: "user-1")

        #expect(result == nil)
    }

    // MARK: - Loading State

    @Test("loadMatches toggles isLoading")
    func loadMatchesLoading() async {
        let match = MockMatchService()
        match.stubbedFetchMatchesPaginated = .success([])

        let (vm, _, _) = makeSUT(matchService: match)

        #expect(vm.isLoading == false)

        await vm.loadMatches(userId: "user-1")

        #expect(vm.isLoading == false)
    }

    // MARK: - Pagination

    @Test("loadMatches sets hasMoreMatches to false when fewer results than page size")
    func loadMatchesSetsHasMoreFalse() async {
        let match = MockMatchService()
        // Return fewer than page size (20) to indicate no more pages
        match.stubbedFetchMatchesPaginated = .success([TestData.makeMatch(id: "m1")])

        let (vm, _, _) = makeSUT(matchService: match)

        await vm.loadMatches(userId: "user-1")

        #expect(vm.hasMoreMatches == false)
        #expect(vm.matches.count == 1)
    }

    @Test("loadMoreMatches appends results to existing matches")
    func loadMoreMatchesAppends() async {
        let match = MockMatchService()
        let initialMatches = [TestData.makeMatch(id: "m1")]
        match.stubbedFetchMatchesPaginated = .success(initialMatches)

        let (vm, _, _) = makeSUT(matchService: match)

        // Load initial page (fewer than 20 → hasMoreMatches will be false)
        // Force hasMoreMatches to true to test loadMore
        await vm.loadMatches(userId: "user-1")
        vm.hasMoreMatches = true // Override for test

        let moreMatches = [TestData.makeMatch(id: "m2")]
        match.stubbedFetchMatchesPaginated = .success(moreMatches)

        await vm.loadMoreMatches(userId: "user-1")

        #expect(vm.matches.count == 2)
        #expect(vm.matches[0].id == "m1")
        #expect(vm.matches[1].id == "m2")
        #expect(vm.isLoadingMore == false)
    }

    @Test("loadMoreMatches does nothing when hasMoreMatches is false")
    func loadMoreMatchesNoMore() async {
        let match = MockMatchService()
        match.stubbedFetchMatchesPaginated = .success([])

        let (vm, _, _) = makeSUT(matchService: match)

        // hasMoreMatches defaults to true, set to false
        vm.hasMoreMatches = false

        await vm.loadMoreMatches(userId: "user-1")

        #expect(match.fetchMatchesPaginatedCallCount == 0)
    }
}
