//  PlaylistImportView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - PlaylistImportView

/// Allows users to browse and import playlists from their Apple Music library.
struct PlaylistImportView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @Environment(\.services) private var services
    @State private var playlists: [Playlist] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var importedIds: Set<String> = []

    let currentUserId: String
    let alreadyImportedIds: Set<String>
    var onImport: (ImportedPlaylist) -> Void

    // MARK: - Body

    var body: some View {
        Group {
            if isLoading {
                ProgressView(String(localized: "Loading playlists..."))
            } else if playlists.isEmpty {
                ContentUnavailableView(
                    String(localized: "No Playlists"),
                    systemImage: "music.note.list",
                    description: Text(String(localized: "Create playlists in Apple Music to import them here."))
                )
            } else {
                playlistList
            }
        }
        .navigationTitle(String(localized: "Import Playlist"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Done")) {
                    dismiss()
                }
            }
        }
        .task {
            await loadPlaylists()
        }
        .alert(
            String(localized: "Error"),
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Playlist List

    private var playlistList: some View {
        List {
            ForEach(playlists) { playlist in
                playlistRow(playlist)
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Playlist Row

    private func playlistRow(_ playlist: Playlist) -> some View {
        let playlistId = playlist.id.rawValue
        let isAlreadyImported = alreadyImportedIds.contains(playlistId) || importedIds.contains(playlistId)

        return HStack(spacing: 12) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.musicRed.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(.musicRed)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                if let curator = playlist.curatorName {
                    Text(curator)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isAlreadyImported {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityLabel(String(localized: "Already imported"))
            } else {
                Button {
                    importPlaylist(playlist)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.musicRed)
                }
                .accessibilityLabel(String(localized: "Import \(playlist.name)"))
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func loadPlaylists() async {
        isLoading = true
        do {
            playlists = try await services.musicService.fetchUserPlaylists()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func importPlaylist(_ playlist: Playlist) {
        let imported = ImportedPlaylist(
            id: playlist.id.rawValue,
            name: playlist.name,
            description: playlist.standardDescription,
            curatorName: playlist.curatorName,
            trackCount: 0,
            artworkURL: playlist.artwork?.url(width: 300, height: 300)?.absoluteString,
            importedAt: Date()
        )
        importedIds.insert(playlist.id.rawValue)
        onImport(imported)
    }
}
