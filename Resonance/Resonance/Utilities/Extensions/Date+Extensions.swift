//  Date+Extensions.swift
//  Resonance

import Foundation

// MARK: - Date Extensions

extension Date {

    /// Returns a human-readable relative time string (e.g., "2 hours ago").
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    /// Returns a formatted string for the date in a short style.
    var shortFormatted: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
