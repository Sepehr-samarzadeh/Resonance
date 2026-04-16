//  ProfileOnRepeatSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileOnRepeatSection

struct ProfileOnRepeatSection: View {

    // MARK: - Properties

    let songs: [OnRepeatSong]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "On Repeat"), systemImage: "repeat")
                .font(.headline)

            if songs.isEmpty {
                ContentUnavailableView {
                    Label(String(localized: "Nothing Yet"), systemImage: "music.note.list")
                } description: {
                    Text(String(localized: "Your most-played songs will show up here."))
                }
                .frame(height: 120)
            } else {
                OnRepeatCardStack(songs: songs)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
