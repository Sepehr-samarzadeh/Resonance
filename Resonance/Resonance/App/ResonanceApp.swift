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
                    OnboardingView(currentUserId: authViewModel.currentUserId ?? "") {
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
                    do {
                        try await appDelegate.notificationService?.registerDeviceToken(token, forUserId: userId)
                    } catch {
                        Log.notification.error("Failed to register device token: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - AppTab

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case search
    case discover
    case connections
    case profile

    var id: String { rawValue }
}

// MARK: - MainTabView

struct MainTabView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State var authViewModel: AuthViewModel
    let appDelegate: AppDelegate
    @State private var playerViewModel: PlayerViewModel?
    @State private var matchViewModel: MatchViewModel?
    @State private var discoveryViewModel: DiscoveryViewModel?
    @State private var selectedTab: AppTab = .home
    @State private var showPlayer = false

    /// Navigation path for programmatic navigation
    @State private var connectionsNavPath = NavigationPath()

    /// Match notification overlay state
    @State private var pendingMatchNotification: Match?
    @State private var matchNotificationUserName: String?

    private var currentUserId: String {
        authViewModel.currentUserId ?? ""
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let playerViewModel, let matchViewModel, let discoveryViewModel, !currentUserId.isEmpty {
                MainTabContent(
                    authViewModel: authViewModel,
                    playerViewModel: playerViewModel,
                    matchViewModel: matchViewModel,
                    discoveryViewModel: discoveryViewModel,
                    appDelegate: appDelegate,
                    selectedTab: $selectedTab,
                    showPlayer: $showPlayer,
                    connectionsNavPath: $connectionsNavPath,
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
            if discoveryViewModel == nil {
                discoveryViewModel = DiscoveryViewModel(
                    discoveryService: services.discoveryService,
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
                do {
                    _ = try await services.matchService.createHistoricalMatchIfSimilar(
                        userId1: userId,
                        userId2: otherUserId
                    )
                } catch {
                    Log.match.error("Historical match comparison failed for \(otherUserId): \(error.localizedDescription)")
                }
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
    let discoveryViewModel: DiscoveryViewModel
    let appDelegate: AppDelegate
    @Binding var selectedTab: AppTab
    @Binding var showPlayer: Bool
    @Binding var connectionsNavPath: NavigationPath
    @Binding var pendingMatchNotification: Match?
    @Binding var matchNotificationUserName: String?
    let currentUserId: String

    @State private var networkMonitor = NetworkMonitor()
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    /// Whether a navigation destination is pushed on the Connections tab.
    private var isInNestedNavigation: Bool {
        !connectionsNavPath.isEmpty
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
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    // MARK: - Tab View

    private var tabView: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "Home"), systemImage: "house.fill", value: AppTab.home) {
                NavigationStack {
                    HomeView(
                        authViewModel: authViewModel,
                        playerViewModel: playerViewModel
                    )
                }
            }

            Tab(String(localized: "Search"), systemImage: "magnifyingglass", value: AppTab.search, role: .search) {
                NavigationStack {
                    SearchView(playerViewModel: playerViewModel)
                }
            }

            Tab(String(localized: "Discover"), systemImage: "binoculars.fill", value: AppTab.discover) {
                NavigationStack {
                    DiscoveryView(
                        viewModel: discoveryViewModel,
                        playerViewModel: playerViewModel,
                        currentUserId: currentUserId
                    )
                    .navigationDestination(for: ResonanceUser.self) { user in
                        UserProfileView(
                            user: user,
                            currentUserId: currentUserId,
                            viewModel: discoveryViewModel
                        )
                    }
                }
            }

            Tab(String(localized: "Connections"), systemImage: "person.2.fill", value: AppTab.connections) {
                NavigationStack(path: $connectionsNavPath) {
                    ConnectionsView(viewModel: matchViewModel, currentUserId: currentUserId)
                        .navigationDestination(for: Match.self) { match in
                            MatchDetailView(
                                match: match,
                                currentUserId: currentUserId
                            )
                        }
                }
            }

            Tab(String(localized: "Profile"), systemImage: "person.crop.circle", value: AppTab.profile) {
                NavigationStack {
                    ProfileView(
                        currentUserId: currentUserId,
                        playerViewModel: playerViewModel,
                        onSignOut: {
                            authViewModel.signOut()
                        },
                        onDeleteAccount: {
                            await authViewModel.deleteAccount()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Deep Link Handling
    private func handleDeepLink(_ deepLink: DeepLink) {
        switch deepLink {
        case .chat(let matchId):
            // Switch to Connections tab and navigate to the match detail
            selectedTab = .connections
            connectionsNavPath = NavigationPath()
            Task {
                do {
                    if let match = try await services.matchService.fetchMatch(id: matchId) {
                        connectionsNavPath.append(match)
                    }
                } catch {
                    Log.match.error("Failed to fetch match for deep link \(matchId): \(error.localizedDescription)")
                }
            }
        case .matches:
            selectedTab = .connections
            connectionsNavPath = NavigationPath()
        }
    }

    // MARK: - Scene Phase

    /// Clears the user's currently-listening status when the app moves to the background,
    /// and restores it when the app returns to the foreground.
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        let userId = currentUserId
        guard !userId.isEmpty else { return }

        switch phase {
        case .background:
            Task {
                do {
                    try await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
                    Log.match.info("Cleared currentlyListening for backgrounded app")
                } catch {
                    Log.user.error("Failed to clear currentlyListening on background: \(error.localizedDescription)")
                }
            }
        case .active:
            // Restore currently listening if music is playing
            if let song = playerViewModel.currentSong, playerViewModel.isPlaying {
                Task {
                    let listening = CurrentlyListening(
                        songId: song.id.rawValue,
                        songName: song.title,
                        artistName: song.artistName,
                        startedAt: Date()
                    )
                    do {
                        try await services.userService.updateCurrentlyListening(userId: userId, listening: listening)
                    } catch {
                        Log.user.error("Failed to restore currentlyListening on active: \(error.localizedDescription)")
                    }
                }
            }
        default:
            break
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
                do {
                    try await services.userService.updateCurrentlyListening(userId: userId, listening: listening)
                } catch {
                    Log.user.error("Failed to update currentlyListening: \(error.localizedDescription)")
                }

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
                do {
                    try await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
                } catch {
                    Log.user.error("Failed to clear currentlyListening: \(error.localizedDescription)")
                }
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
                do {
                    try await services.userService.updateCurrentlyListening(userId: userId, listening: nil)
                } catch {
                    Log.user.error("Failed to clear currentlyListening on pause: \(error.localizedDescription)")
                }
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
                do {
                    try await services.userService.updateCurrentlyListening(userId: userId, listening: listening)
                } catch {
                    Log.user.error("Failed to update currentlyListening on resume: \(error.localizedDescription)")
                }
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
    @Binding var selectedTab: AppTab

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
                        selectedTab = .connections
                    }
                }
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(100)
        }
    }
}
