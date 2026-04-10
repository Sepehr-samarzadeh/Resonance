//  ProfileView.swift
//  Resonance

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {

    // MARK: - Properties

    @State private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    let currentUserId: String
    var onSignOut: () -> Void

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader

                statsSection

                topArtistsSection

                genresSection

                listeningHistorySection

                signOutButton
            }
            .padding()
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
            NavigationStack {
                EditProfileView(viewModel: viewModel, userId: currentUserId)
            }
        }
        .task {
            await viewModel.loadProfile(userId: currentUserId)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(.purple.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
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

    // MARK: - Stats Section

    private var statsSection: some View {
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

    private var topArtistsSection: some View {
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

    private var genresSection: some View {
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

    private var listeningHistorySection: some View {
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

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
