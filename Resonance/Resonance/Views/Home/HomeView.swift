//  HomeView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - HomeView

struct HomeView: View {

    // MARK: - Properties

    @State private var viewModel = HomeViewModel()
    @State private var authViewModel: AuthViewModel

    init(authViewModel: AuthViewModel) {
        _authViewModel = State(initialValue: authViewModel)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                greetingSection

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    recentlyPlayedSection
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "Home"))
        .task {
            await viewModel.loadData()
        }
        .refreshable {
            await viewModel.loadData()
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

    private var recentlyPlayedSection: some View {
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
