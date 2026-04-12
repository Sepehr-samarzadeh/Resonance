import SwiftUI

// MARK: - Apple Music Theme Color

extension Color {
    /// Apple Music red (#FC3C44) — the primary accent color used throughout the app.
    static let musicRed = Color(red: 252 / 255, green: 60 / 255, blue: 68 / 255)
}

extension ShapeStyle where Self == Color {
    /// Apple Music red (#FC3C44) — the primary accent color used throughout the app.
    static var musicRed: Color { .musicRed }
}
