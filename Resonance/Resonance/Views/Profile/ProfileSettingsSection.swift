//  ProfileSettingsSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileSettingsSection

struct ProfileSettingsSection: View {

    // MARK: - Properties

    let userEmail: String?
    let authProvider: AuthProvider?
    var onSignOut: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "Account"), systemImage: "gearshape")
                .font(.headline)

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.purple)
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
