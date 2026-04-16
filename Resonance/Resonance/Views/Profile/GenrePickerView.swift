//  GenrePickerView.swift
//  Resonance

import SwiftUI

// MARK: - GenrePickerView

/// A view pushed onto the navigation stack that lets users toggle Apple Music genres.
struct GenrePickerView: View {

    // MARK: - Properties

    @Binding var selectedGenres: [String]

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(Constants.Genres.all, id: \.self) { genre in
                    Button {
                        toggleGenre(genre)
                    } label: {
                        HStack {
                            if let emoji = Constants.Genres.emojis[genre] {
                                Text(emoji)
                                    .font(.title3)
                            }

                            Text(genre)
                                .foregroundStyle(.primary)

                            Spacer()

                            if selectedGenres.contains(genre) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.musicRed)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .disabled(!selectedGenres.contains(genre) && selectedGenres.count >= Constants.ProfileLimits.maxGenres)
                    .accessibilityAddTraits(selectedGenres.contains(genre) ? .isSelected : [])
                    .accessibilityLabel(genre)
                }
            } footer: {
                Text(String(localized: "\(selectedGenres.count)/\(Constants.ProfileLimits.maxGenres) genres selected"))
            }
        }
        .navigationTitle(String(localized: "Select Genres"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func toggleGenre(_ genre: String) {
        if let index = selectedGenres.firstIndex(of: genre) {
            selectedGenres.remove(at: index)
        } else if selectedGenres.count < Constants.ProfileLimits.maxGenres {
            selectedGenres.append(genre)
        }
    }
}
