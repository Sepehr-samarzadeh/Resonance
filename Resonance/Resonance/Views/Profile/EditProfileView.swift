//  EditProfileView.swift
//  Resonance

import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {

    // MARK: - Properties

    @State var viewModel: ProfileViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss
    @State private var newGenre = ""

    // MARK: - Body

    var body: some View {
        Form {
            basicInfoSection

            aboutSection

            favoriteSongSection

            genresSection

            socialLinksSection
        }
        .navigationTitle(String(localized: "Edit Profile"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(String(localized: "Cancel")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(String(localized: "Save")) {
                    Task {
                        await viewModel.saveProfile(userId: userId)
                        dismiss()
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
        .overlay {
            if viewModel.isSaving {
                ProgressView()
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section {
            TextField(String(localized: "Your name"), text: $viewModel.editDisplayName)
            TextField(String(localized: "e.g. she/her, he/him, they/them"), text: $viewModel.editPronouns)
        } header: {
            Text(String(localized: "Basic Info"))
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            TextField(
                String(localized: "Tell people about yourself"),
                text: $viewModel.editBio,
                axis: .vertical
            )
            .lineLimit(3...6)

            TextField(
                String(localized: "What's your vibe right now?"),
                text: $viewModel.editMood
            )
        } header: {
            Text(String(localized: "About"))
        } footer: {
            Text(String(localized: "Your mood is shown on your profile card."))
        }
    }

    // MARK: - Favorite Song Section

    private var favoriteSongSection: some View {
        Section {
            TextField(String(localized: "Song name"), text: $viewModel.editFavoriteSongName)
            TextField(String(localized: "Artist name"), text: $viewModel.editFavoriteSongArtist)
        } header: {
            Text(String(localized: "Favorite Song"))
        } footer: {
            Text(String(localized: "The song that defines you. Displayed on your profile."))
        }
    }

    // MARK: - Genres Section

    private var genresSection: some View {
        Section {
            ForEach(viewModel.editFavoriteGenres, id: \.self) { genre in
                Text(genre)
            }
            .onDelete { indexSet in
                viewModel.editFavoriteGenres.remove(atOffsets: indexSet)
            }

            HStack {
                TextField(String(localized: "Add genre"), text: $newGenre)
                    .submitLabel(.done)
                    .onSubmit {
                        addGenre()
                    }
                Button(String(localized: "Add")) {
                    addGenre()
                }
                .disabled(newGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text(String(localized: "Favorite Genres"))
        }
    }

    // MARK: - Social Links Section

    private var socialLinksSection: some View {
        Section {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.pink)
                    .accessibilityHidden(true)
                TextField(String(localized: "Instagram username"), text: $viewModel.editInstagram)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                TextField(String(localized: "Spotify username"), text: $viewModel.editSpotify)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            HStack {
                Image(systemName: "at")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                TextField(String(localized: "X / Twitter handle"), text: $viewModel.editTwitter)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        } header: {
            Text(String(localized: "Social Links"))
        } footer: {
            Text(String(localized: "Shown on your profile so matches can find you."))
        }
    }

    // MARK: - Helpers

    private func addGenre() {
        let trimmed = newGenre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !viewModel.editFavoriteGenres.contains(trimmed) {
            viewModel.editFavoriteGenres.append(trimmed)
        }
        newGenre = ""
    }
}
