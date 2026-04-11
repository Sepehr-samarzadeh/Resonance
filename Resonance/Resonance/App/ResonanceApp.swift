//  ResonanceApp.swift
//  Resonance
//
//  Created by Sepehr on 07/04/2026.
//

import SwiftUI
import MusicKit

// MARK: - ResonanceApp

@main
struct ResonanceApp: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var services = ServiceContainer()
    @State private var authViewModel: AuthViewModel?

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if let authViewModel {
                    RootView(authViewModel: authViewModel, appDelegate: appDelegate)
                } else {
                    ProgressView()
                }
            }
            .environment(\.services, services)
            .task {
                // Wire AppDelegate to use shared services
                appDelegate.notificationService = services.notificationService

                if authViewModel == nil {
                    authViewModel = AuthViewModel(
                        authService: services.authService,
                        userService: services.userService,
                        notificationService: services.notificationService
                    )
                }
            }
        }
    }
}

// MARK: - RootView

struct RootView: View {

    // MARK: - Properties

    @State var authViewModel: AuthViewModel
    let appDelegate: AppDelegate
    @AppStorage(Constants.StorageKeys.hasCompletedOnboarding) private var onboardingCompleted = false

    // MARK: - Body

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                if onboardingCompleted {
                    MainTabView(authViewModel: authViewModel, appDelegate: appDelegate)
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                }
            } else {
                LoginView(authViewModel: authViewModel)
            }
        }
        .task {
            await authViewModel.listenForAuthChanges()
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn, let userId = authViewModel.currentUser?.id,
               let token = appDelegate.latestDeviceToken {
                Task {
                    try? await appDelegate.notificationService?.registerDeviceToken(token, forUserId: userId)
                }
            }
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State var authViewModel: AuthViewModel
    let appDelegate: AppDelegate
    @State private var playerViewModel: PlayerViewModel?
    @State private var matchViewModel: MatchViewModel?
    @State private var selectedTab = 0
    @State private var showPlayer = false

    /// Navigation paths for programmatic navigation
    @State private var matchesNavPath = NavigationPath()
    @State private var messagesNavPath = NavigationPath()

    /// Match notification overlay state
    @State private var pendingMatchNotification: Match?
    @State private var matchNotificationUserName: String?

    private var currentUserId: String {
        authViewModel.currentUser?.id ?? ""
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let playerViewModel {
                mainContent(playerViewModel: playerViewModel)
            } else {
                ProgressView()
            }
        }
        .task {
            if playerViewModel == nil {
                let vm = PlayerViewModel(
                    musicService: services.musicService,
                    userService: services.userService
                )
                vm.startObservingNowPlaying()
                playerViewModel = vm
            }
            if matchViewModel == nil {
                matchViewModel = MatchViewModel(
                    matchService: services.matchService,
                    userService: services.userService
                )
            }

            // Trigger historical matching periodically
            await runHistoricalMatching()
        }
    }

    @ViewBuilder
    private func mainContent(playerViewModel: PlayerViewModel) -> some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                Tab(String(localized: "Home"), systemImage: "house.fill", value: 0) {
                    NavigationStack {
                        HomeView(authViewModel: authViewModel)
                    }
                }

                Tab(String(localized: "Charts"), systemImage: "chart.line.uptrend.xyaxis", value: 1) {
                    NavigationStack {
                        MusicChartView()
                    }
                }

                Tab(String(localized: "Matches"), systemImage: "person.2.fill", value: 2) {
                    NavigationStack(path: $matchesNavPath) {
                        if let matchViewModel {
                            MatchFeedView(viewModel: matchViewModel, currentUserId: currentUserId)
                                .navigationDestination(for: Match.self) { match in
                                    MatchDetailView(
                                        match: match,
                                        currentUserId: currentUserId
                                    )
                                }
                        }
                    }
                }

                Tab(String(localized: "Messages"), systemImage: "bubble.left.and.bubble.right.fill", value: 3) {
                    NavigationStack(path: $messagesNavPath) {
                        if let matchViewModel {
                            ChatListView(viewModel: matchViewModel, currentUserId: currentUserId)
                                .navigationDestination(for: Match.self) { match in
                                    ChatView(
                                        match: match,
                                        currentUserId: currentUserId
                                    )
                                }
                        }
                    }
                }

                Tab(String(localized: "Profile"), systemImage: "person.crop.circle", value: 4) {
                    NavigationStack {
                        ProfileView(currentUserId: currentUserId) {
                            authViewModel.signOut()
                        }
                    }
                }
            }

            NowPlayingBar(playerViewModel: playerViewModel) {
                showPlayer = true
            }
            .padding(.bottom, 50)

            // Match notification overlay
            if let match = pendingMatchNotification,
               let userName = matchNotificationUserName {
                MatchNotificationView(
                    match: match,
                    otherUserName: userName,
                    onDismiss: {
                        pendingMatchNotification = nil
                        matchNotificationUserName = nil
                    },
                    onViewMatch: {
                        pendingMatchNotification = nil
                        matchNotificationUserName = nil
                        selectedTab = 2 // Switch to Matches tab
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showPlayer) {
            PlayerView(viewModel: playerViewModel)
        }
        .onChange(of: playerViewModel.currentSong) { _, newSong in
            handleSongChange(newSong, playerViewModel: playerViewModel)
        }
        .onChange(of: appDelegate.pendingDeepLink) { _, deepLink in
            guard let deepLink else { return }
            handleDeepLink(deepLink)
            appDelegate.pendingDeepLink = nil
        }
        .animation(.spring(duration: 0.4), value: pendingMatchNotification != nil)
    }

    // MARK: - Deep Link Handling

    /// Navigates to the appropriate screen based on a deep-link.
    private func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .chat(let matchId):
            // Switch to Messages tab and fetch the match to push it
            selectedTab = 3
            messagesNavPath = NavigationPath()
            Task {
                if let match = try? await services.matchService.fetchMatch(id: matchId) {
                    messagesNavPath.append(match)
                }
            }
        case .matches:
            selectedTab = 2
            matchesNavPath = NavigationPath()
        }
    }

    // MARK: - Song Change Handling

    /// When the currently playing song changes, update Firestore and check for matches.
    private func handleSongChange(_ song: Song?, playerViewModel: PlayerViewModel) {
        let userId = currentUserId
        guard !userId.isEmpty else { return }

        Task {
            // Save listening session for the new song
            await playerViewModel.saveListeningSession(userId: userId)

            // Update "currently listening" status in Firestore
            if let song {
                let listening = CurrentlyListening(
                    songId: song.id.rawValue,
                    songName: song.title,
                    artistName: song.artistName,
                    startedAt: Date()
                )
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: listening)

                // Check for realtime matches (song + artist) using the shared MatchViewModel
                if let matchVM = matchViewModel {
                    let newMatch = await matchVM.checkForRealtimeMatch(
                        userId: userId,
                        songId: song.id.rawValue,
                        songName: song.title,
                        artistName: song.artistName
                    )

                    // Show match notification if we got a new match
                    if let newMatch {
                        let otherUser = await matchVM.getOtherUser(match: newMatch, currentUserId: userId)
                        pendingMatchNotification = newMatch
                        matchNotificationUserName = otherUser?.displayName ?? String(localized: "Someone")
                    }
                }
            } else {
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
            }
        }
    }

    // MARK: - Historical Matching

    /// Runs historical matching against other users once per session.
    private func runHistoricalMatching() async {
        let userId = currentUserId
        guard !userId.isEmpty else { return }

        do {
            // Get a sample of other users to compare with
            let otherUserIds = try await services.matchService.fetchRecentUserIds(excluding: userId, limit: 20)
            for otherUserId in otherUserIds {
                _ = try? await services.matchService.createHistoricalMatchIfSimilar(
                    userId1: userId,
                    userId2: otherUserId
                )
            }
        } catch {
            print("MainTabView: Historical matching error — \(error.localizedDescription)")
        }
    }
}
