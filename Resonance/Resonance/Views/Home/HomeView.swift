//  HomeView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - HomeView

struct HomeView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: HomeViewModel?
    @State var authViewModel: AuthViewModel
    let playerViewModel: PlayerViewModel

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                HomeContent(
                    viewModel: viewModel,
                    authViewModel: authViewModel,
                    playerViewModel: playerViewModel
                )
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Home"))
        .task {
            if viewModel == nil {
                viewModel = HomeViewModel(
                    musicService: services.musicService,
                    userService: services.userService
                )
            }
            await viewModel?.loadData()

            // Update currently listening status
            if let userId = authViewModel.currentUser?.id,
               let song = viewModel?.recentlyPlayed.first {
                await viewModel?.updateCurrentlyListening(userId: userId, song: song)
            }
        }
        .refreshable {
            await viewModel?.loadData()
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage = viewModel?.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - HomeContent

/// Main scrollable content for the Home tab.
/// Separated into its own struct to scope observation tracking.
private struct HomeContent: View {
    let viewModel: HomeViewModel
    let authViewModel: AuthViewModel
    let playerViewModel: PlayerViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                HomeGreetingSection(
                    displayName: authViewModel.currentUser?.displayName ?? ""
                )

                InlineNowPlayingView(playerViewModel: playerViewModel)
                    .frame(maxWidth: .infinity)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    HomeFeaturedArtistsSection(
                        artists: viewModel.featuredArtists
                    )

                    HomeListeningHistoryCard(
                        songs: viewModel.recentlyPlayed,
                        playerViewModel: playerViewModel
                    )

                    HomeTopChartsSection(
                        songs: viewModel.chartPreview,
                        playerViewModel: playerViewModel
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - HomeGreetingSection

/// Greeting header showing the user's name and tagline.
private struct HomeGreetingSection: View {
    let displayName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Hello, \(displayName)"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "Discover your musical matches"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
