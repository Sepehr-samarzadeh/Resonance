//  CardModifier.swift
//  Resonance

import SwiftUI

// MARK: - CardModifier

struct CardModifier: ViewModifier {

    // MARK: - Properties

    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.08), radius: shadowRadius, y: 2)
    }
}

// MARK: - View Extension

extension View {

    /// Applies a card-style background with material, corner radius, and shadow.
    func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 4) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}
