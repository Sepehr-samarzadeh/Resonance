//  ProfileHeaderView.swift
//  Resonance

import SwiftUI

// MARK: - ProfileHeaderView

struct ProfileHeaderView: View {

    // MARK: - Properties

    let user: ResonanceUser?
    let isUploadingPhoto: Bool

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Gradient background header
            ZStack(alignment: .bottom) {
                // Gradient backdrop
                LinearGradient(
                    colors: [.purple.opacity(0.6), .purple.opacity(0.2), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                .ignoresSafeArea(edges: .top)

                // Photo + info overlay at bottom of gradient
                VStack(spacing: 12) {
                    photoSection

                    nameSection
                }
                .offset(y: 60)
            }

            // Spacer for offset content
            Spacer()
                .frame(height: 70)

            // Bio
            if let bio = user?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Mood badge
            if let mood = user?.mood, !mood.isEmpty {
                Label(mood, systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                    .padding(.top, 8)
            }

            // Member since
            if let createdAt = user?.createdAt {
                Text(String(localized: "Member since \(createdAt, format: .dateTime.month(.wide).year())"))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        ZStack {
            profilePhoto

            if isUploadingPhoto {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay {
                        ProgressView()
                            .tint(.purple)
                    }
            }
        }
    }

    private var profilePhoto: some View {
        Group {
            if let photoURL = user?.photoURL,
               let url = URL(string: photoURL) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } placeholder: {
                    ProgressView()
                        .frame(width: 140, height: 140)
                }
            } else {
                placeholderPhoto
            }
        }
        .overlay {
            Circle()
                .strokeBorder(.background, lineWidth: 4)
                .frame(width: 140, height: 140)
        }
        .accessibilityLabel(String(localized: "Profile photo"))
    }

    private var placeholderPhoto: some View {
        Circle()
            .fill(.purple.opacity(0.2))
            .frame(width: 140, height: 140)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)
            }
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(spacing: 4) {
            Text(user?.displayName ?? "")
                .font(.title2)
                .fontWeight(.bold)

            if let pronouns = user?.pronouns, !pronouns.isEmpty {
                Text(pronouns)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
