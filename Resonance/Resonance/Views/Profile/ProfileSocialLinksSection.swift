//  ProfileSocialLinksSection.swift
//  Resonance

import SwiftUI

// MARK: - ProfileSocialLinksSection

struct ProfileSocialLinksSection: View {

    // MARK: - Properties

    let socialLinks: SocialLinks?
    @Environment(\.openURL) private var openURL

    // MARK: - Body

    var body: some View {
        let links = socialLinks
        let hasLinks = [links?.instagram, links?.spotify, links?.twitter]
            .compactMap { $0 }
            .contains { !$0.isEmpty }

        if hasLinks {
            VStack(alignment: .leading, spacing: 12) {
                Label(String(localized: "Social Links"), systemImage: "link")
                    .font(.headline)

                VStack(spacing: 10) {
                    if let instagram = links?.instagram, !instagram.isEmpty {
                        socialLinkRow(
                            icon: "camera.fill",
                            label: instagram,
                            color: .pink,
                            url: URL(string: "https://instagram.com/\(instagram)")
                        )
                    }
                    if let spotify = links?.spotify, !spotify.isEmpty {
                        socialLinkRow(
                            icon: "music.note",
                            label: spotify,
                            color: .green,
                            url: URL(string: "https://open.spotify.com/user/\(spotify)")
                        )
                    }
                    if let twitter = links?.twitter, !twitter.isEmpty {
                        socialLinkRow(
                            icon: "at",
                            label: twitter,
                            color: .blue,
                            url: URL(string: "https://x.com/\(twitter)")
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Social Link Row

    private func socialLinkRow(icon: String, label: String, color: Color, url: URL?) -> some View {
        Button {
            if let url {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Constants.UI.cornerRadiusMedium))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "Open \(label)"))
    }
}
