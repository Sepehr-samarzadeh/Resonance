//  View+Extensions.swift
//  Resonance

import SwiftUI

// MARK: - View Extensions

extension View {

    /// Applies a conditional modifier to the view.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Hides the view based on a condition.
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }
}
