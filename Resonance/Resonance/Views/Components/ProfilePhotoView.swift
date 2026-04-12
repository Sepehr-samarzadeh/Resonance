//  ProfilePhotoView.swift
//  Resonance

import SwiftUI

// MARK: - ProfilePhotoView

/// Reusable profile photo circle that shows a `CachedAsyncImage` when a URL
/// is available, or a fallback icon on a tinted circle.
struct ProfilePhotoView: View {

    // MARK: - Properties

    let photoURL: String?
    let size: CGFloat
    var fallbackIcon: String = "person.fill"

    // MARK: - Body

    var body: some View {
        if let urlString = photoURL, let url = URL(string: urlString) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } placeholder: {
                placeholderCircle
            }
            .accessibilityHidden(true)
        } else {
            placeholderCircle
        }
    }

    // MARK: - Placeholder

    private var placeholderCircle: some View {
        Circle()
            .fill(.musicRed.opacity(0.2))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: fallbackIcon)
                    .foregroundStyle(.musicRed)
                    .font(.system(size: size * 0.35))
            }
            .accessibilityHidden(true)
    }
}
