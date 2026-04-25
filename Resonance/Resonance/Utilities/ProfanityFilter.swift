//  ProfanityFilter.swift
//  Resonance

import Foundation

// MARK: - ProfanityFilter

/// A simple client-side profanity filter that checks text against a bundled
/// word list. This satisfies Apple's App Store Guideline 1.2 requirement
/// for filtering objectionable material in user-generated content.
enum ProfanityFilter: Sendable {

    /// Returns `true` if the text contains a prohibited word.
    nonisolated static func containsProhibitedContent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let words = lowercased.components(separatedBy: .alphanumerics.inverted)
        return words.contains { !$0.isEmpty && bannedWords.contains($0) }
    }

    // MARK: - Banned Words

    /// A minimal set of commonly banned words. Sourced from public profanity
    /// lists. This is intentionally conservative — server-side moderation
    /// handles edge cases.
    private nonisolated static let bannedWords: Set<String> = [
        "ass", "asshole", "bastard", "bitch", "bollocks",
        "bullshit", "cock", "crap", "cunt", "damn",
        "dick", "douche", "fag", "faggot", "fuck",
        "fucking", "goddamn", "horseshit", "jackass", "jizz",
        "motherfucker", "negro", "nigga", "nigger", "piss",
        "prick", "pussy", "retard", "retarded", "shit",
        "shitty", "slut", "twat", "wanker", "whore",
    ]
}
