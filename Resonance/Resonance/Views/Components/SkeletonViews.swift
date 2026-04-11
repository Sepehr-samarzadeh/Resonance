//  SkeletonViews.swift
//  Resonance

import SwiftUI

// MARK: - SkeletonMatchCard

/// A skeleton placeholder that mimics the shape of a MatchCardView.
struct SkeletonMatchCard: View {

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(.gray.opacity(0.15))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 120, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 180, height: 10)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shimmer()
        .accessibilityHidden(true)
    }
}

// MARK: - SkeletonChatRow

/// A skeleton placeholder that mimics the shape of a ChatRowView.
struct SkeletonChatRow: View {

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.gray.opacity(0.15))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.15))
                        .frame(width: 100, height: 14)

                    Spacer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.15))
                        .frame(width: 40, height: 10)
                }

                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 200, height: 12)
            }
        }
        .shimmer()
        .accessibilityHidden(true)
    }
}

// MARK: - SkeletonSongRow

/// A skeleton placeholder that mimics the shape of a ChartSongRow or SearchSongRow.
struct SkeletonSongRow: View {

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.15))
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 100, height: 10)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .shimmer()
        .accessibilityHidden(true)
    }
}

// MARK: - SkeletonProfileHeader

/// A skeleton placeholder that mimics the shape of the redesigned profile header.
struct SkeletonProfileHeader: View {

    var body: some View {
        VStack(spacing: 16) {
            // Gradient backdrop placeholder
            RoundedRectangle(cornerRadius: 0)
                .fill(.gray.opacity(0.1))
                .frame(height: 120)
                .overlay(alignment: .bottom) {
                    Circle()
                        .fill(.gray.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .offset(y: 60)
                }

            Spacer()
                .frame(height: 50)

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 140, height: 20)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 80, height: 12)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.15))
                    .frame(width: 220, height: 12)
            }

            // Stats skeleton
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.15))
                            .frame(width: 30, height: 20)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray.opacity(0.15))
                            .frame(width: 50, height: 10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .shimmer()
        .accessibilityHidden(true)
    }
}
