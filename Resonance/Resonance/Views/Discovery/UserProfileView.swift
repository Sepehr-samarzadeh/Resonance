//  UserProfileView.swift
//  Resonance

import SwiftUI
import OSLog

// MARK: - UserProfileView

/// Displays another user's public profile with a "Connect" / "Requested" / "Accept" button.
struct UserProfileView: View {

    // MARK: - Properties

    let user: ResonanceUser
    let currentUserId: String
    @State var viewModel: DiscoveryViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var isSending = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                profileHeader

                if !user.favoriteGenres.isEmpty {
                    genresSection
                }

                if !user.topArtists.isEmpty {
                    topArtistsSection
                }

                if let bio = user.bio, !bio.isEmpty {
                    bioSection(bio)
                }

                actionButton
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(user.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ProfilePhotoView(photoURL: user.photoURL, size: 120)

            Text(user.displayName)
                .font(.title2.weight(.bold))

            if let pronouns = user.pronouns, !pronouns.isEmpty {
                Text(pronouns)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let mood = user.mood, !mood.isEmpty {
                Text(mood)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }

            if let listening = user.currentlyListening, let songName = listening.songName {
                HStack(spacing: 6) {
                    Image(systemName: "headphones")
                        .font(.caption)
                        .foregroundStyle(.musicRed)
                    Text(String(localized: "Listening to \(songName)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Genres

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Favorite Genres"))
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(user.favoriteGenres, id: \.self) { genre in
                    let emoji = Constants.Genres.emojis[genre] ?? ""
                    Text("\(emoji) \(genre)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Top Artists

    private var topArtistsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Top Artists"))
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(user.topArtists) { artist in
                        ArtistCard(artist: artist)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bio

    private func bioSection(_ bio: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "About"))
                .font(.headline)
            Text(bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        let status = viewModel.relationshipStatus(with: user.id ?? "")

        switch status {
        case .none:
            Button {
                Task {
                    isSending = true
                    await viewModel.sendRequest(to: user.id ?? "", from: currentUserId)
                    isSending = false
                }
            } label: {
                Label(String(localized: "Connect"), systemImage: "person.badge.plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.musicRed)
            .disabled(isSending)

        case .requestSent:
            Button {
                // Find the outgoing request to cancel
                if let request = viewModel.outgoingRequests.first(where: { $0.receiverId == user.id }) {
                    Task {
                        await viewModel.cancelRequest(request)
                    }
                }
            } label: {
                Label(String(localized: "Request Sent"), systemImage: "clock")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

        case .requestReceived:
            HStack(spacing: 12) {
                Button {
                    if let request = viewModel.incomingRequests.first(where: { $0.senderId == user.id }) {
                        Task {
                            await viewModel.acceptRequest(request)
                            dismiss()
                        }
                    }
                } label: {
                    Label(String(localized: "Accept"), systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.musicRed)

                Button {
                    if let request = viewModel.incomingRequests.first(where: { $0.senderId == user.id }) {
                        Task {
                            await viewModel.declineRequest(request)
                            dismiss()
                        }
                    }
                } label: {
                    Label(String(localized: "Decline"), systemImage: "xmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
    }
}
