//  DiscoveryView.swift
//  Resonance

import SwiftUI
import MusicKit
import OSLog

// MARK: - DiscoveryView

struct DiscoveryView: View {

    // MARK: - Properties

    @State var viewModel: DiscoveryViewModel
    let playerViewModel: PlayerViewModel
    let currentUserId: String

    @State private var hasLoadedSimilar = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                requestsBanner

                listeningNowSection

                similarUsersSection
            }
            .padding(.vertical)
        }
        .navigationTitle(String(localized: "Discover"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    RequestsView(viewModel: viewModel, currentUserId: currentUserId)
                } label: {
                    requestsBadge
                }
                .accessibilityLabel(String(localized: "Friend requests"))
            }
        }
        .task {
            await viewModel.loadRequests(userId: currentUserId)
            viewModel.listenForIncomingRequests(userId: currentUserId)
        }
        .task(id: playerViewModel.currentSong?.id) {
            await viewModel.loadListeningNow(
                songId: playerViewModel.currentSong?.id.rawValue,
                artistName: playerViewModel.currentSong?.artistName,
                currentUserId: currentUserId
            )
        }
        .task {
            guard !hasLoadedSimilar else { return }
            hasLoadedSimilar = true
            await viewModel.loadSimilarUsers(userId: currentUserId)
        }
        .refreshable {
            async let listeners: () = viewModel.loadListeningNow(
                songId: playerViewModel.currentSong?.id.rawValue,
                artistName: playerViewModel.currentSong?.artistName,
                currentUserId: currentUserId
            )
            async let similar: () = viewModel.loadSimilarUsers(userId: currentUserId)
            async let requests: () = viewModel.loadRequests(userId: currentUserId)
            _ = await (listeners, similar, requests)
        }
    }

    // MARK: - Requests Banner

    @ViewBuilder
    private var requestsBanner: some View {
        if !viewModel.incomingRequests.isEmpty {
            NavigationLink {
                RequestsView(viewModel: viewModel, currentUserId: currentUserId)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundStyle(.musicRed)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "\(viewModel.incomingRequests.count) pending request(s)"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(String(localized: "Tap to review"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Requests Badge

    private var requestsBadge: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.body)

            if !viewModel.incomingRequests.isEmpty {
                Text("\(viewModel.incomingRequests.count)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.musicRed, in: Circle())
                    .offset(x: 8, y: -8)
            }
        }
    }

    // MARK: - Listening Now Section

    @ViewBuilder
    private var listeningNowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: String(localized: "Listening Now"),
                icon: "headphones",
                subtitle: playerViewModel.currentSong != nil
                    ? String(localized: "People listening to the same music as you")
                    : String(localized: "Play a song to discover who's listening too")
            )

            if viewModel.isLoadingListeners {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if viewModel.listeningNowUsers.isEmpty {
                emptyStateCard(
                    icon: "waveform",
                    message: playerViewModel.currentSong != nil
                        ? String(localized: "No one else is listening right now")
                        : String(localized: "Start playing music to discover listeners")
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.listeningNowUsers) { user in
                            NavigationLink(value: user) {
                                DiscoveryUserCard(
                                    user: user,
                                    subtitle: user.currentlyListening?.songName,
                                    relationshipStatus: viewModel.relationshipStatus(with: user.id ?? "")
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Similar Users Section

    @ViewBuilder
    private var similarUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                title: String(localized: "Similar Taste"),
                icon: "sparkles",
                subtitle: String(localized: "People who love the same music as you")
            )

            if viewModel.isLoadingSimilar {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if viewModel.similarUsers.isEmpty {
                emptyStateCard(
                    icon: "music.note.list",
                    message: String(localized: "No similar users found yet. Keep listening!")
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.similarUsers, id: \.user.id) { item in
                        NavigationLink(value: item.user) {
                            DiscoverySimilarRow(
                                user: item.user,
                                score: item.score,
                                relationshipStatus: viewModel.relationshipStatus(with: item.user.id ?? "")
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, icon: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.title3.weight(.bold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private func emptyStateCard(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal)
    }
}

// MARK: - DiscoveryUserCard

/// Horizontal scrolling card for "Listening Now" users.
struct DiscoveryUserCard: View {
    let user: ResonanceUser
    let subtitle: String?
    let relationshipStatus: RelationshipStatus

    var body: some View {
        VStack(spacing: 8) {
            ProfilePhotoView(photoURL: user.photoURL, size: 72)

            Text(user.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            statusIndicator
        }
        .frame(width: 100)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch relationshipStatus {
        case .requestSent:
            Text(String(localized: "Requested"))
                .font(.caption2)
                .foregroundStyle(.musicRed)
        case .requestReceived:
            Text(String(localized: "Wants to connect"))
                .font(.caption2)
                .foregroundStyle(.musicRed)
        case .none:
            EmptyView()
        }
    }
}

// MARK: - DiscoverySimilarRow

/// Row for "Similar Taste" list.
struct DiscoverySimilarRow: View {
    let user: ResonanceUser
    let score: Double
    let relationshipStatus: RelationshipStatus

    var body: some View {
        HStack(spacing: 12) {
            ProfilePhotoView(photoURL: user.photoURL, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(.subheadline.weight(.medium))

                if !user.favoriteGenres.isEmpty {
                    Text(user.favoriteGenres.prefix(3).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                MatchScoreBadge(score: score)

                switch relationshipStatus {
                case .requestSent:
                    Text(String(localized: "Requested"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                case .requestReceived:
                    Text(String(localized: "Respond"))
                        .font(.caption2)
                        .foregroundStyle(.musicRed)
                case .none:
                    EmptyView()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
    }
}
