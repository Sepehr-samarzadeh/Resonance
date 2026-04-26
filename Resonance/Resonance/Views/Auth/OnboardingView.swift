//  OnboardingView.swift
//  Resonance

import SwiftUI
import MusicKit
import OSLog

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: - Properties

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.services) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
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

                notificationPage
                    .tag(4)

                readyPage
                    .tag(5)
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

            switch musicAuthStatus {
            case .authorized:
                Label(String(localized: "Access Granted"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

            case .denied:
                VStack(spacing: 12) {
                    Label(String(localized: "Access Denied"), systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.headline)

                    Text(String(localized: "You can enable Apple Music access in Settings. Without it, some features like matching and listening history won't work."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        if let url = URL(string: "App-prefs:root") {
                            openURL(url)
                        }
                    } label: {
                        Text(String(localized: "Open Settings"))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 40)
                }

            case .restricted:
                VStack(spacing: 12) {
                    Label(String(localized: "Access Restricted"), systemImage: "lock.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.headline)

                    Text(String(localized: "Apple Music access is restricted on this device, possibly by parental controls. Some features won't be available."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

            default:
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
        .task {
            musicAuthStatus = services.musicService.authorizationStatus
        }
    }

    // MARK: - Notification Page

    private var notificationPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: largeIconSize))
                .foregroundStyle(.musicRed)
                .accessibilityHidden(true)

            Text(String(localized: "Stay in the Loop"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text(String(localized: "Get notified when someone matches with you or sends a message."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                appDelegate.requestNotificationPermission()
                withAnimation { currentPage = 5 }
            } label: {
                Text(String(localized: "Enable Notifications"))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.musicRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Button {
                withAnimation { currentPage = 5 }
            } label: {
                Text(String(localized: "Not Now"))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)
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
