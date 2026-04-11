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

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                homeContent(viewModel: viewModel)
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

    // MARK: - Home Content

    @ViewBuilder
    private func homeContent(viewModel: HomeViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                greetingSection

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    recentlyPlayedSection(viewModel: viewModel)
                }
            }
            .padding()
        }
    }

    // MARK: - Greeting Section

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Hello, \(authViewModel.currentUser?.displayName ?? "")"))
                .font(.title2)
                .fontWeight(.bold)

            Text(String(localized: "Discover your musical matches"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Recently Played Section

    @ViewBuilder
    private func recentlyPlayedSection(viewModel: HomeViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recently Played"))
                .font(.headline)

            if viewModel.recentlyPlayed.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Recent Songs"),
                    systemImage: "music.note",
                    description: Text(String(localized: "Start listening to see your recent tracks here."))
                )
            } else {
                ForEach(viewModel.recentlyPlayed, id: \.id) { song in
                    SongRow(song: song)
                }
            }
        }
    }
}
