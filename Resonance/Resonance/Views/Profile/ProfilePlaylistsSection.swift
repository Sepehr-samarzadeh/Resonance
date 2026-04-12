//  ProfilePlaylistsSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfilePlaylistsSection

/// Displays imported Apple Music playlists on the user's profile.
struct ProfilePlaylistsSection: View {

    // MARK: - Properties

    let playlists: [ImportedPlaylist]
    let playerViewModel: PlayerViewModel
    var onImportTapped: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(String(localized: "Playlists"), systemImage: "music.note.list")
                    .font(.headline)

                Spacer()

                Button(String(localized: "Import"), systemImage: "plus.circle") {
                    onImportTapped()
                }
                .font(.caption)
                .foregroundStyle(.musicRed)
            }

            if playlists.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "No Playlists"), systemImage: "music.note.list")
                } description: {
                    Text(String(localized: "Import playlists from Apple Music to show them on your profile."))
                }
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(playlists) { playlist in
                            NavigationLink {
                                ImportedPlaylistDetailView(
                                    playlist: playlist,
                                    playerViewModel: playerViewModel
                                )
                            } label: {
                                playlistCard(playlist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Playlist Card

    private func playlistCard(_ playlist: ImportedPlaylist) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            playlistArtwork(playlist)
                .frame(width: 120, height: 120)

            Text(playlist.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)

            if let curator = playlist.curatorName {
                Text(curator)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "\(playlist.name) playlist"))
        .accessibilityHint(String(localized: "Tap to view songs"))
    }

    // MARK: - Playlist Artwork

    @ViewBuilder
    private func playlistArtwork(_ playlist: ImportedPlaylist) -> some View {
        if let urlString = playlist.artworkURL,
           let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                playlistPlaceholder
            }
        } else {
            playlistPlaceholder
        }
    }

    private var playlistPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.musicRed.opacity(0.15))
            .frame(width: 120, height: 120)
            .overlay {
                Image(systemName: "music.note.list")
                    .font(.title2)
                    .foregroundStyle(.musicRed)
            }
    }
}
