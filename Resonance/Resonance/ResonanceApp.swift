//  ResonanceApp.swift
//  Resonance
//
//  Created by Sepehr on 07/04/2026.
//

import SwiftUI

// MARK: - ResonanceApp

@main
struct ResonanceApp: App {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var authViewModel = AuthViewModel()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            RootView(authViewModel: authViewModel)
        }
    }
}

// MARK: - RootView

struct RootView: View {

    // MARK: - Properties

    @State var authViewModel: AuthViewModel
    @AppStorage("hasCompletedOnboarding") private var onboardingCompleted = false

    // MARK: - Body

    var body: some View {
        Group {
            if authViewModel.isSignedIn {
                if onboardingCompleted {
                    MainTabView(authViewModel: authViewModel)
                } else {
                    OnboardingView {
                        onboardingCompleted = true
                    }
                }
            } else {
                LoginView()
            }
        }
        .task {
            await authViewModel.listenForAuthChanges()
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {

    // MARK: - Properties

    @State var authViewModel: AuthViewModel
    @State private var playerViewModel = PlayerViewModel()
    @State private var selectedTab = 0
    @State private var showPlayer = false

    private var currentUserId: String {
        authViewModel.currentUser?.id ?? ""
    }

    // MARK: - Body

    var body: some View {
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
                    NavigationStack {
                        MatchFeedView(currentUserId: currentUserId)
                            .navigationDestination(for: Match.self) { match in
                                MatchDetailView(
                                    match: match,
                                    currentUserId: currentUserId
                                )
                            }
                    }
                }

                Tab(String(localized: "Messages"), systemImage: "bubble.left.and.bubble.right.fill", value: 3) {
                    NavigationStack {
                        ChatListView(currentUserId: currentUserId)
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
        }
        .sheet(isPresented: $showPlayer) {
            PlayerView(viewModel: playerViewModel)
        }
    }
}
