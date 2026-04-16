//  EditProfileView.swift
//  Resonance

import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {

    // MARK: - Properties

    @State var viewModel: ProfileViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed

    private var isSaveDisabled: Bool {
        viewModel.isSaving || viewModel.editDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                .disabled(isSaveDisabled)
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
                .onChange(of: viewModel.editDisplayName) { _, newValue in
                    if newValue.count > Constants.ProfileLimits.displayNameMax {
                        viewModel.editDisplayName = String(newValue.prefix(Constants.ProfileLimits.displayNameMax))
                    }
                }
            TextField(String(localized: "e.g. she/her, he/him, they/them"), text: $viewModel.editPronouns)
                .onChange(of: viewModel.editPronouns) { _, newValue in
                    if newValue.count > Constants.ProfileLimits.pronounsMax {
                        viewModel.editPronouns = String(newValue.prefix(Constants.ProfileLimits.pronounsMax))
                    }
                }
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
            .onChange(of: viewModel.editBio) { _, newValue in
                if newValue.count > Constants.ProfileLimits.bioMax {
                    viewModel.editBio = String(newValue.prefix(Constants.ProfileLimits.bioMax))
                }
            }

            TextField(
                String(localized: "What's your vibe right now?"),
                text: $viewModel.editMood
            )
            .onChange(of: viewModel.editMood) { _, newValue in
                if newValue.count > Constants.ProfileLimits.moodMax {
                    viewModel.editMood = String(newValue.prefix(Constants.ProfileLimits.moodMax))
                }
            }
        } header: {
            Text(String(localized: "About"))
        } footer: {
            Text(String(localized: "\(viewModel.editBio.count)/\(Constants.ProfileLimits.bioMax) · Your mood is shown on your profile card."))
        }
    }

    // MARK: - Favorite Song Section

    private var favoriteSongSection: some View {
        Section {
            TextField(String(localized: "Song name"), text: $viewModel.editFavoriteSongName)
                .onChange(of: viewModel.editFavoriteSongName) { _, newValue in
                    if newValue.count > Constants.ProfileLimits.songNameMax {
                        viewModel.editFavoriteSongName = String(newValue.prefix(Constants.ProfileLimits.songNameMax))
                    }
                }
            TextField(String(localized: "Artist name"), text: $viewModel.editFavoriteSongArtist)
                .onChange(of: viewModel.editFavoriteSongArtist) { _, newValue in
                    if newValue.count > Constants.ProfileLimits.artistNameMax {
                        viewModel.editFavoriteSongArtist = String(newValue.prefix(Constants.ProfileLimits.artistNameMax))
                    }
                }
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
                HStack {
                    if let emoji = Constants.Genres.emojis[genre] {
                        Text(emoji)
                    }
                    Text(genre)
                }
            }
            .onDelete { indexSet in
                viewModel.editFavoriteGenres.remove(atOffsets: indexSet)
            }

            NavigationLink {
                GenrePickerView(selectedGenres: $viewModel.editFavoriteGenres)
            } label: {
                Label(String(localized: "Add Genres"), systemImage: "plus.circle")
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
                    .onChange(of: viewModel.editInstagram) { _, newValue in
                        if newValue.count > Constants.ProfileLimits.usernameMax {
                            viewModel.editInstagram = String(newValue.prefix(Constants.ProfileLimits.usernameMax))
                        }
                    }
            }
            HStack {
                Image(systemName: "music.note")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                TextField(String(localized: "Spotify username"), text: $viewModel.editSpotify)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: viewModel.editSpotify) { _, newValue in
                        if newValue.count > Constants.ProfileLimits.usernameMax {
                            viewModel.editSpotify = String(newValue.prefix(Constants.ProfileLimits.usernameMax))
                        }
                    }
            }
            HStack {
                Image(systemName: "at")
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                TextField(String(localized: "X / Twitter handle"), text: $viewModel.editTwitter)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: viewModel.editTwitter) { _, newValue in
                        if newValue.count > Constants.ProfileLimits.usernameMax {
                            viewModel.editTwitter = String(newValue.prefix(Constants.ProfileLimits.usernameMax))
                        }
                    }
            }
        } header: {
            Text(String(localized: "Social Links"))
        } footer: {
            Text(String(localized: "Shown on your profile so matches can find you."))
        }
    }

}
