//  ResonanceApp.swift
//  Resonance
//
//  Created by Sepehr on 07/04/2026.
//

import SwiftUI
import MusicKit
import GoogleSignIn
import OSLog

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
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
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
                        .transition(.opacity)
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                    .transition(.opacity)
                }
            } else {
                LoginView(authViewModel: authViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: authViewModel.isSignedIn)
        .animation(.easeInOut(duration: 0.4), value: onboardingCompleted)
        .task {
            await authViewModel.listenForAuthChanges()
        }
        .onChange(of: authViewModel.isSignedIn) { _, isSignedIn in
            if isSignedIn, let userId = authViewModel.currentUserId,
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

    /// Navigation path for programmatic navigation
    @State private var matchesNavPath = NavigationPath()
    @State private var messagesNavPath = NavigationPath()

    /// Match notification overlay state
    @State private var pendingMatchNotification: Match?
    @State private var matchNotificationUserName: String?

    private var currentUserId: String {
        authViewModel.currentUserId ?? ""
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let playerViewModel, let matchViewModel, !currentUserId.isEmpty {
                MainTabContent(
                    authViewModel: authViewModel,
                    playerViewModel: playerViewModel,
                    matchViewModel: matchViewModel,
                    appDelegate: appDelegate,
                    selectedTab: $selectedTab,
                    showPlayer: $showPlayer,
                    matchesNavPath: $matchesNavPath,
                    messagesNavPath: $messagesNavPath,
                    pendingMatchNotification: $pendingMatchNotification,
                    matchNotificationUserName: $matchNotificationUserName,
                    currentUserId: currentUserId
                )
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
            Log.match.error("Historical matching error: \(error.localizedDescription)")
        }
    }
}

// MARK: - MainTabContent

/// Extracted into its own `View` struct so that observation from
/// `playerViewModel`, `networkMonitor`, etc. is scoped to this view
/// rather than re-evaluating the entire `MainTabView` (and every tab)
/// on every playback state change.
private struct MainTabContent: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    let authViewModel: AuthViewModel
    let playerViewModel: PlayerViewModel
    let matchViewModel: MatchViewModel
    let appDelegate: AppDelegate
    @Binding var selectedTab: Int
    @Binding var showPlayer: Bool
    @Binding var matchesNavPath: NavigationPath
    @Binding var messagesNavPath: NavigationPath
    @Binding var pendingMatchNotification: Match?
    @Binding var matchNotificationUserName: String?
    let currentUserId: String

    @State private var networkMonitor = NetworkMonitor()

    // MARK: - Body

    /// Whether a navigation destination is pushed on the Matches or Messages tab.
    private var isInNestedNavigation: Bool {
        !matchesNavPath.isEmpty || !messagesNavPath.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            tabView

            if !isInNestedNavigation {
                NowPlayingBar(playerViewModel: playerViewModel) {
                    showPlayer = true
                }
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            OfflineBanner(networkMonitor: networkMonitor)

            MatchNotificationOverlay(
                pendingMatch: $pendingMatchNotification,
                matchUserName: $matchNotificationUserName,
                selectedTab: $selectedTab
            )
        }
        .animation(.easeInOut(duration: 0.25), value: isInNestedNavigation)
        .sheet(isPresented: $showPlayer) {
            PlayerView(viewModel: playerViewModel)
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: playerViewModel.currentSong) { _, newSong in
            handleSongChange(newSong)
        }
        .onChange(of: playerViewModel.isPlaying) { _, isPlaying in
            handlePlaybackStateChange(isPlaying: isPlaying)
        }
        .onChange(of: appDelegate.pendingDeepLink) { _, deepLink in
            guard let deepLink else { return }
            handleDeepLink(deepLink)
            appDelegate.pendingDeepLink = nil
        }
        .animation(.spring(duration: 0.4), value: pendingMatchNotification != nil)
        .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
    }

    // MARK: - Tab View

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "Home"), systemImage: "house.fill", value: 0) {
                NavigationStack {
                    HomeView(
                        authViewModel: authViewModel,
                        playerViewModel: playerViewModel
                    )
                }
            }

            Tab(String(localized: "Search"), systemImage: "magnifyingglass", value: 1) {
                NavigationStack {
                    SearchView(playerViewModel: playerViewModel)
                }
            }

            Tab(String(localized: "Matches"), systemImage: "person.2.fill", value: 2) {
                NavigationStack(path: $matchesNavPath) {
                    MatchFeedView(viewModel: matchViewModel, currentUserId: currentUserId)
                        .navigationDestination(for: Match.self) { match in
                            MatchDetailView(
                                match: match,
                                currentUserId: currentUserId
                            )
                        }
                }
            }

            Tab(String(localized: "Messages"), systemImage: "bubble.left.and.bubble.right.fill", value: 3) {
                NavigationStack(path: $messagesNavPath) {
                    ChatListView(viewModel: matchViewModel, currentUserId: currentUserId)
                        .navigationDestination(for: Match.self) { match in
                            MatchDetailView(
                                match: match,
                                currentUserId: currentUserId
                            )
                        }
                }
            }

            Tab(String(localized: "Profile"), systemImage: "person.crop.circle", value: 4) {
                NavigationStack {
                    ProfileView(
                        currentUserId: currentUserId,
                        playerViewModel: playerViewModel
                    ) {
                        authViewModel.signOut()
                    }
                }
            }
        }
    }

    // MARK: - Deep Link Handling

    /// Navigates to the appropriate screen based on a deep-link.
    private func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .chat(let matchId):
            // Switch to Messages tab and navigate to the match detail
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
    private func handleSongChange(_ song: Song?) {
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
                    artworkURL: song.artwork?.url(width: 300, height: 300)?.absoluteString,
                    startedAt: Date()
                )
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: listening)

                // Check for realtime matches (song + artist) using the shared MatchViewModel
                let newMatch = await matchViewModel.checkForRealtimeMatch(
                    userId: userId,
                    songId: song.id.rawValue,
                    songName: song.title,
                    artistName: song.artistName
                )

                // Show match notification if we got a new match
                if let newMatch {
                    let otherUser = await matchViewModel.getOtherUser(match: newMatch, currentUserId: userId)
                    pendingMatchNotification = newMatch
                    matchNotificationUserName = otherUser?.displayName ?? String(localized: "Someone")
                }
            } else {
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
            }
        }
    }

    // MARK: - Playback State Change

    /// When playback stops (pause), clear the currently-listening status in Firestore
    /// so other users no longer see us as actively listening.
    private func handlePlaybackStateChange(isPlaying: Bool) {
        let userId = currentUserId
        guard !userId.isEmpty else { return }

        if !isPlaying {
            Task {
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
            }
        } else if let song = playerViewModel.currentSong {
            // Resumed playback — re-broadcast currently listening
            let listening = CurrentlyListening(
                songId: song.id.rawValue,
                songName: song.title,
                artistName: song.artistName,
                artworkURL: song.artwork?.url(width: 300, height: 300)?.absoluteString,
                startedAt: Date()
            )
            Task {
                try? await services.userService.updateCurrentlyListening(userId: userId, listening: listening)
            }
        }
    }
}

// MARK: - OfflineBanner

/// Isolated view for network status observation.
/// Prevents network-status changes from re-evaluating the parent view.
private struct OfflineBanner: View {
    let networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            VStack {
                HStack(spacing: 8) {
                    Image(systemName: "wifi.slash")
                        .font(.subheadline)
                    Text(String(localized: "No internet connection"))
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.red.gradient, in: Capsule())
                .padding(.top, 4)

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "No internet connection"))
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(99)
        }
    }
}

// MARK: - MatchNotificationOverlay

/// Isolated view for match notification display.
private struct MatchNotificationOverlay: View {
    @Binding var pendingMatch: Match?
    @Binding var matchUserName: String?
    @Binding var selectedTab: Int

    var body: some View {
        if let match = pendingMatch,
           let userName = matchUserName {
            MatchNotificationView(
                match: match,
                otherUserName: userName,
                onDismiss: {
                    withAnimation(.spring(duration: 0.3)) {
                        pendingMatch = nil
                        matchUserName = nil
                    }
                },
                onViewMatch: {
                    withAnimation(.spring(duration: 0.3)) {
                        pendingMatch = nil
                        matchUserName = nil
                        selectedTab = 2
                    }
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(100)
        }
    }
}
