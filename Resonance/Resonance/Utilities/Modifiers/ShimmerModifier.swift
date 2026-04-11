//  ShimmerModifier.swift
//  Resonance

import SwiftUI

// MARK: - ShimmerModifier

/// A modifier that applies a shimmering loading effect over a view.
/// Respects the Reduce Motion accessibility setting.
struct ShimmerModifier: ViewModifier {

    // MARK: - Properties

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay {
                if reduceMotion {
                    Color.gray.opacity(0.12)
                } else {
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.25),
                            .clear
                        ],
                        startPoint: .init(x: phase - 0.5, y: 0.5),
                        endPoint: .init(x: phase + 0.5, y: 0.5)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .task(id: reduceMotion) {
                guard !reduceMotion else { return }
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 2
                }
            }
    }
}

// MARK: - View Extension

extension View {

    /// Applies a shimmer loading effect over the view.
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
