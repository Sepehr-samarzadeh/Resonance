//  ProfileSettingsSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileSettingsSection

struct ProfileSettingsSection: View {

    // MARK: - Properties

    let currentUserId: String
    let userEmail: String?
    let authProvider: AuthProvider?
    var onSignOut: () -> Void
    var onDeleteAccount: () async -> Void

    @State private var showDeleteConfirmation = false

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

                Divider()
                    .padding(.leading, 52)

                // Blocked Users
                NavigationLink {
                    BlockedUsersView(currentUserId: currentUserId)
                } label: {
                    settingsRow(
                        icon: "hand.raised.fill",
                        title: String(localized: "Blocked Users"),
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

}
