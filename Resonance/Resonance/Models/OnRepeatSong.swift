//  OnRepeatSong.swift
//  Resonance

import Foundation

// MARK: - OnRepeatSong

/// A song aggregated from listening history, ranked by play count.
struct OnRepeatSong: Identifiable, Sendable {
    let id: String  // songId
    let songName: String
    let artistName: String
    let genre: String?
    let artworkURL: String?
    let playCount: Int
    let totalSeconds: Int
    let lastPlayed: Date
}
