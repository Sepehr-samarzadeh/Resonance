//  EditProfileView.swift
//  Resonance

import SwiftUI

// MARK: - EditProfileView

struct EditProfileView: View {

    // MARK: - Properties

    @State var viewModel: ProfileViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Form {
            Section(String(localized: "Display Name")) {
                TextField(String(localized: "Your name"), text: $viewModel.editDisplayName)
            }

            Section(String(localized: "Bio")) {
                TextField(String(localized: "Tell people about yourself"), text: $viewModel.editBio, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section(String(localized: "Favorite Genres")) {
                ForEach(viewModel.editFavoriteGenres, id: \.self) { genre in
                    Text(genre)
                }
                .onDelete { indexSet in
                    viewModel.editFavoriteGenres.remove(atOffsets: indexSet)
                }

                HStack {
                    @State var newGenre = ""
                    TextField(String(localized: "Add genre"), text: $newGenre)
                    Button(String(localized: "Add")) {
                        let trimmed = newGenre.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            viewModel.editFavoriteGenres.append(trimmed)
                            newGenre = ""
                        }
                    }
                    .disabled(newGenre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
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
}
