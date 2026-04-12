//  ProfileView.swift
//  Resonance

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: ProfileViewModel?
    @State private var showEditProfile = false
    @State private var hasAppeared = false
    let currentUserId: String
    let playerViewModel: PlayerViewModel
    var onSignOut: () -> Void

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                ProfileContentView(
                    viewModel: viewModel,
                    currentUserId: currentUserId,
                    playerViewModel: playerViewModel,
                    onSignOut: onSignOut
                )
            } else {
                SkeletonProfileHeader()
                    .padding()
            }
        }
        .navigationTitle(String(localized: "Profile"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Edit"), systemImage: "pencil") {
                    showEditProfile = true
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            if let viewModel {
                NavigationStack {
                    EditProfileView(viewModel: viewModel, userId: currentUserId)
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ProfileViewModel(
                    userService: services.userService,
                    musicService: services.musicService
                )
            }
            await viewModel?.loadProfile(userId: currentUserId)

            // Trigger staggered appearance
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
        .task(id: currentUserId) {
            // Listen for real-time profile changes (e.g. from other devices)
            await viewModel?.listenForProfileChanges(userId: currentUserId)
        }
        .refreshable {
            await viewModel?.loadProfile(userId: currentUserId)
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

// MARK: - ProfileContentView

/// Main scrollable content of the profile, composed of extracted section views.
struct ProfileContentView: View {

    // MARK: - Properties

    let viewModel: ProfileViewModel
    let currentUserId: String
    let playerViewModel: PlayerViewModel
    var onSignOut: () -> Void

    @State private var sectionAppeared = false
    @State private var showPlaylistImport = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with gradient, photo, name, bio, mood
                ProfileHeaderView(
                    user: viewModel.user,
                    isUploadingPhoto: viewModel.isUploadingPhoto
                )

                // All sections below the header
                VStack(spacing: 24) {
                    // Stats
                    ProfileStatsSection(
                        user: viewModel.user,
                        sessionCount: viewModel.listeningHistory.count
                    )

                    // Currently listening
                    if let currentlyListening = viewModel.user?.currentlyListening,
                       currentlyListening.songName != nil {
                        ProfileCurrentlyListeningCard(
                            currentlyListening: currentlyListening
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Favorite song
                    if let song = viewModel.user?.favoriteSong {
                        ProfileFavoriteSongSection(song: song)
                    }

                    // Imported playlists
                    ProfilePlaylistsSection(
                        playlists: viewModel.importedPlaylists,
                        playerViewModel: playerViewModel,
                        onImportTapped: { showPlaylistImport = true }
                    )

                    // Top artists
                    ProfileTopArtistsSection(
                        artists: viewModel.user?.topArtists ?? [],
                        onAutoPopulate: {
                            Task {
                                await viewModel.autoPopulateTopArtists(userId: currentUserId)
                            }
                        }
                    )

                    // Genres
                    ProfileGenresSection(
                        genres: viewModel.user?.favoriteGenres ?? []
                    )

                    // Social links
                    ProfileSocialLinksSection(
                        socialLinks: viewModel.user?.socialLinks
                    )

                    // Listening history
                    ProfileListeningHistorySection(
                        sessions: viewModel.listeningHistory
                    )

                    // Settings & account
                    ProfileSettingsSection(
                        userEmail: viewModel.user?.email,
                        authProvider: viewModel.user?.authProvider,
                        onSignOut: onSignOut
                    )
                }
                .padding(.horizontal)
                .opacity(sectionAppeared ? 1 : 0)
                .offset(y: sectionAppeared ? 0 : 20)
            }
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showPlaylistImport) {
            // Reload playlists from Firestore when the sheet is dismissed
            // to ensure the profile reflects any imports that were saved.
            Task {
                await viewModel.loadImportedPlaylists(userId: currentUserId)
            }
        } content: {
            NavigationStack {
                PlaylistImportView(
                    currentUserId: currentUserId,
                    alreadyImportedIds: Set(viewModel.importedPlaylists.map(\.id)),
                    onImport: { playlist in
                        Task {
                            await viewModel.saveImportedPlaylist(
                                userId: currentUserId,
                                playlist: playlist
                            )
                        }
                    }
                )
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                sectionAppeared = true
            }
        }
    }
}
