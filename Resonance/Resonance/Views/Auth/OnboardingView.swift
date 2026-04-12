//  OnboardingView.swift
//  Resonance

import SwiftUI
import MusicKit
import OSLog

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var musicAuthStatus: MusicAuthorization.Status = .notDetermined
    @State private var selectedGenres: Set<String> = []
    @State private var selectedArtists: [TasteArtist] = []
    @State private var libraryArtistNames: [String] = []
    @State private var isSaving = false
    @ScaledMetric(relativeTo: .largeTitle) private var largeIconSize: CGFloat = 80
    @ScaledMetric(relativeTo: .title) private var mediumIconSize: CGFloat = 60

    let currentUserId: String
    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                musicAccessPage
                    .tag(1)

                OnboardingGenreView(selectedGenres: $selectedGenres) {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                OnboardingArtistView(
                    selectedArtists: $selectedArtists,
                    libraryArtistNames: $libraryArtistNames
                ) {
                    withAnimation { currentPage = 4 }
                }
                .tag(3)

                readyPage
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(
            LinearGradient(
                colors: [.musicRed.opacity(0.2), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Welcome Page

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: largeIconSize))
                .foregroundStyle(.musicRed)
                .accessibilityHidden(true)

            Text(String(localized: "Welcome to Resonance"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(String(localized: "Find people who share your music taste. Listen together, connect through rhythm."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            nextButton
        }
        .padding()
    }

    // MARK: - Music Access Page

    private var musicAccessPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "apple.logo")
                .font(.system(size: mediumIconSize))
                .foregroundStyle(.white)
                .accessibilityHidden(true)

            Text(String(localized: "Apple Music Access"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Resonance needs access to Apple Music to discover what you listen to and find your matches."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if musicAuthStatus == .authorized {
                Label(String(localized: "Access Granted"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button {
                    Task {
                        musicAuthStatus = await services.musicService.requestAuthorization()
                    }
                } label: {
                    Text(String(localized: "Grant Access"))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.musicRed)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            nextButton
        }
        .padding()
    }

    // MARK: - Ready Page

    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: largeIconSize))
                .foregroundStyle(.musicRed)
                .symbolEffect(.bounce, isActive: !reduceMotion)
                .accessibilityHidden(true)

            Text(String(localized: "You're All Set"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Start listening and discover people who resonate with your music taste."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                Task { await saveTasteProfileAndComplete() }
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(String(localized: "Get Started"))
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.musicRed)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isSaving)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .padding()
    }

    // MARK: - Next Button

    private var nextButton: some View {
        Button {
            withAnimation {
                currentPage += 1
            }
        } label: {
            Text(String(localized: "Next"))
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(.musicRed.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 40)
    }

    // MARK: - Save Taste Profile

    /// Saves the user's taste profile to Firestore, then completes onboarding.
    private func saveTasteProfileAndComplete() async {
        guard !currentUserId.isEmpty else {
            onComplete()
            return
        }

        isSaving = true

        let profile = TasteProfile(
            selectedGenres: Array(selectedGenres),
            selectedArtists: selectedArtists,
            libraryArtistNames: libraryArtistNames,
            updatedAt: Date()
        )

        do {
            try await services.userService.saveTasteProfile(userId: currentUserId, profile: profile)

            // Also update favoriteGenres and topArtists on the main user doc
            // so they show up on the profile immediately
            try await services.userService.updateFavoriteGenres(userId: currentUserId, genres: Array(selectedGenres))

            let topArtists = selectedArtists.map { artist in
                TopArtist(id: artist.id, name: artist.name, artworkURL: artist.artworkURL)
            }
            try await services.userService.updateTopArtists(userId: currentUserId, artists: topArtists)
        } catch {
            Log.auth.error("Failed to save taste profile: \(error.localizedDescription)")
        }

        isSaving = false
        onComplete()
    }
}
