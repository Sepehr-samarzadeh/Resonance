//  StorageServiceProtocol.swift
//  Resonance

import Foundation

// MARK: - StorageServiceProtocol

/// Protocol defining the interface for file storage services.
/// Used by `ProfileViewModel` for testability via dependency injection.
protocol StorageServiceProtocol: Sendable {

    /// Uploads a profile photo for the given user.
    /// - Returns: The download URL string of the uploaded photo.
    func uploadProfilePhoto(imageData: Data, userId: String) async throws -> String

    /// Deletes the profile photo for the given user.
    func deleteProfilePhoto(userId: String) async throws
}
