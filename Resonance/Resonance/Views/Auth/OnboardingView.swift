//  OnboardingView.swift
//  Resonance

import SwiftUI
import MusicKit

// MARK: - OnboardingView

struct OnboardingView: View {

    // MARK: - Properties

    @Environment(\.services) private var services
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentPage = 0
    @State private var musicAuthStatus: MusicAuthorization.Status = .notDetermined
    @ScaledMetric(relativeTo: .largeTitle) private var largeIconSize: CGFloat = 80
    @ScaledMetric(relativeTo: .title) private var mediumIconSize: CGFloat = 60
    var onComplete: () -> Void

    // MARK: - Body

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                welcomePage
                    .tag(0)

                musicAccessPage
                    .tag(1)

                readyPage
                    .tag(2)
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
                onComplete()
            } label: {
                Text(String(localized: "Get Started"))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.musicRed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
}
