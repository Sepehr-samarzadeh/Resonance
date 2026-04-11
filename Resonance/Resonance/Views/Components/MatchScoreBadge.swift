//  MatchScoreBadge.swift
//  Resonance

import SwiftUI

// MARK: - MatchScoreBadge

struct MatchScoreBadge: View {

    // MARK: - Properties

    let score: Double?

    // MARK: - Body

    var body: some View {
        if let score {
            Text(score, format: .percent.precision(.fractionLength(0)))
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor(for: score))
                .clipShape(Capsule())
                .accessibilityLabel(String(localized: "Match score: \(Int(score * 100)) percent"))
        }
    }

    // MARK: - Helpers

    private func badgeColor(for score: Double) -> Color {
        switch score {
        case 0.7...:
            .green
        case 0.4..<0.7:
            .orange
        default:
            .red
        }
    }
}
