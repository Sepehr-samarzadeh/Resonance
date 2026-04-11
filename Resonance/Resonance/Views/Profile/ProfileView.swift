//  ProfileView.swift
//  Resonance

import SwiftUI
import PhotosUI

// MARK: - ProfileView

struct ProfileView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @State private var viewModel: ProfileViewModel?
    @State private var showEditProfile = false
    @State private var selectedPhoto: PhotosPickerItem?
    let currentUserId: String
    var onSignOut: () -> Void

    // MARK: - Body

    var body: some View {
        Group {
            if let viewModel {
                profileContent(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(String(localized: "Profile"))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "Edit")) {
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
                    musicService: services.musicService,
                    storageService: services.storageService
                )
            }
            await viewModel?.loadProfile(userId: currentUserId)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                await handlePhotoSelection(newValue)
            }
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

    // MARK: - Photo Selection

    private func handlePhotoSelection(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        await viewModel?.uploadProfilePhoto(imageData: data, userId: currentUserId)
    }

    // MARK: - Profile Content

    @ViewBuilder
    private func profileContent(viewModel: ProfileViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(viewModel: viewModel)

                statsSection(viewModel: viewModel)

                topArtistsSection(viewModel: viewModel)

                genresSection(viewModel: viewModel)

                listeningHistorySection(viewModel: viewModel)

                signOutButton
            }
            .padding()
        }
    }

    // MARK: - Profile Header

    @ViewBuilder
    private func profileHeader(viewModel: ProfileViewModel) -> some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                profilePhotoContent
            }

            if viewModel.isUploadingPhoto {
                ProgressView()
                    .padding(.top, 4)
            }

            Text(viewModel.user?.displayName ?? "")
                .font(.title2)
                .fontWeight(.bold)

            if let bio = viewModel.user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var profilePhotoContent: some View {
        if let photoURL = viewModel?.user?.photoURL,
           let url = URL(string: photoURL) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: 100, height: 100)
            }
        } else {
            placeholderPhoto
        }
    }

    private var placeholderPhoto: some View {
        Circle()
            .fill(.purple.opacity(0.2))
            .frame(width: 100, height: 100)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(.purple)
                    .clipShape(Circle())
                    .accessibilityHidden(true)
            }
            .accessibilityLabel(String(localized: "Profile photo, tap to change"))
    }

    // MARK: - Stats Section

    @ViewBuilder
    private func statsSection(viewModel: ProfileViewModel) -> some View {
        HStack(spacing: 32) {
            statItem(
                title: String(localized: "Artists"),
                value: "\(viewModel.user?.topArtists.count ?? 0)"
            )
            statItem(
                title: String(localized: "Genres"),
                value: "\(viewModel.user?.favoriteGenres.count ?? 0)"
            )
            statItem(
                title: String(localized: "Sessions"),
                value: "\(viewModel.listeningHistory.count)"
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Top Artists Section

    @ViewBuilder
    private func topArtistsSection(viewModel: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "Top Artists"))
                    .font(.headline)
                Spacer()
                Button(String(localized: "Auto-populate")) {
                    Task {
                        await viewModel.autoPopulateTopArtists(userId: currentUserId)
                    }
                }
                .font(.caption)
            }

            if let artists = viewModel.user?.topArtists, !artists.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(artists) { artist in
                            ArtistCard(artist: artist)
                        }
                    }
                }
            } else {
                Text(String(localized: "No top artists yet."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Genres Section

    @ViewBuilder
    private func genresSection(viewModel: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Favorite Genres"))
                .font(.headline)

            if let genres = viewModel.user?.favoriteGenres, !genres.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(genres, id: \.self) { genre in
                        Text(genre)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text(String(localized: "No favorite genres set."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Listening History Section

    @ViewBuilder
    private func listeningHistorySection(viewModel: ProfileViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recent Listening"))
                .font(.headline)

            if viewModel.listeningHistory.isEmpty {
                Text(String(localized: "No listening history yet."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.listeningHistory) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.songName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(session.artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(session.listenedAt, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button(role: .destructive) {
            onSignOut()
        } label: {
            Text(String(localized: "Sign Out"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}
