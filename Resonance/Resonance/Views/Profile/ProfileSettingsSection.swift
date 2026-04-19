//  ProfileSettingsSection.swift
//  Resonance

import SwiftUI
#if DEBUG
@preconcurrency import FirebaseFunctions
#endif

// MARK: - ProfileSettingsSection

struct ProfileSettingsSection: View {

    // MARK: - Properties

    let currentUserId: String
    let userEmail: String?
    let authProvider: AuthProvider?
    var onSignOut: () -> Void
    var onDeleteAccount: () async -> Void

    @State private var showDeleteConfirmation = false

    #if DEBUG
    @Environment(\.services) private var services
    @State private var isSeedingMatch = false
    @State private var seedResult: String?
    #endif

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 0) {
                    // Account email
                    if let email = userEmail, !email.isEmpty {
                        settingsRow(
                            icon: "envelope.fill",
                            title: String(localized: "Email"),
                            detail: email
                        )

                    Divider()
                        .padding(.leading, 52)
                }

                // Auth provider
                if let provider = authProvider {
                    settingsRow(
                        icon: provider == .apple ? "apple.logo" : "globe",
                        title: String(localized: "Sign-in Method"),
                        detail: provider == .apple
                            ? String(localized: "Apple")
                            : String(localized: "Google")
                    )

                    Divider()
                        .padding(.leading, 52)
                }

                // App version
                settingsRow(
                    icon: "info.circle",
                    title: String(localized: "App Version"),
                    detail: appVersion
                )

                Divider()
                    .padding(.leading, 52)

                // Privacy Policy
                Link(destination: Constants.Legal.privacyPolicyURL) {
                    settingsRow(
                        icon: "hand.raised.fill",
                        title: String(localized: "Privacy Policy"),
                        detail: ""
                    )
                }

                Divider()
                    .padding(.leading, 52)

                // Terms of Service
                Link(destination: Constants.Legal.termsOfServiceURL) {
                    settingsRow(
                        icon: "doc.text.fill",
                        title: String(localized: "Terms of Service"),
                        detail: ""
                    )
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Sign out button
            Button(role: .destructive) {
                onSignOut()
            } label: {
                HStack {
                    Spacer()
                    Label(String(localized: "Sign Out"), systemImage: "rectangle.portrait.and.arrow.right")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Delete account button
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Label(String(localized: "Delete Account"), systemImage: "trash")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .confirmationDialog(
                String(localized: "Delete Account"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Delete Account"), role: .destructive) {
                    Task { await onDeleteAccount() }
                }
            } message: {
                Text(String(localized: "This will permanently delete your account and all associated data. This action cannot be undone."))
            }

            #if DEBUG
            debugSeedSection
            #endif
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.musicRed)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - App Version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Debug Seed Section

    #if DEBUG
    private var debugSeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Debug"), systemImage: "ladybug")
                .font(.headline)
                .foregroundStyle(.orange)

            VStack(spacing: 12) {
                Button {
                    Task { await seedTestMatch() }
                } label: {
                    HStack {
                        Spacer()
                        if isSeedingMatch {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label(String(localized: "Seed Test Match & User"), systemImage: "person.badge.plus")
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(isSeedingMatch)

                if let seedResult {
                    Text(seedResult)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    /// Songs used for debug match seeding — picked at random each time.
    private static let seedSongs: [(id: String, name: String, artist: String)] = [
        ("1440852322", "Blinding Lights", "The Weeknd"),
        ("1613600188", "Anti-Hero", "Taylor Swift"),
        ("1574210519", "As It Was", "Harry Styles"),
        ("1556175085", "Heat Waves", "Glass Animals"),
        ("1450330685", "bad guy", "Billie Eilish"),
        ("1468058165", "Watermelon Sugar", "Harry Styles"),
        ("1440818839", "Bohemian Rhapsody", "Queen"),
        ("1443163568", "Smells Like Teen Spirit", "Nirvana"),
        ("1452601224", "Someone You Loved", "Lewis Capaldi"),
        ("1544494996", "Levitating", "Dua Lipa"),
    ]

    /// Creates a test match via the `seedTestMatch` Cloud Function.
    /// The Cloud Function uses admin SDK to create a test user and match,
    /// bypassing security rules that would prevent client-side test data creation.
    private func seedTestMatch() async {
        isSeedingMatch = true
        seedResult = nil

        guard !currentUserId.isEmpty else {
            seedResult = String(localized: "Failed: No signed-in user ID")
            isSeedingMatch = false
            return
        }

        let functions = Functions.functions()
        let testUserId = "debug-test-user-\(UUID().uuidString.prefix(8))"
        let song = Self.seedSongs.randomElement()!

        do {
            let data: [String: Any] = [
                "testUserId": testUserId,
                "triggerSong": [
                    "id": song.id,
                    "name": song.name,
                    "artistName": song.artist
                ]
            ]
            _ = try await functions.httpsCallable("seedTestMatch").call(data)

            seedResult = String(localized: "Matched on \(song.name) by \(song.artist). Check Matches tab!")
        } catch {
            seedResult = String(localized: "Failed: \(error.localizedDescription)")
        }

        isSeedingMatch = false
    }
    #endif
}
