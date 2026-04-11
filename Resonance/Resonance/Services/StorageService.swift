//  StorageService.swift
//  Resonance

import Foundation
@preconcurrency import FirebaseStorage

// MARK: - StorageService

actor StorageService: StorageServiceProtocol {

    // MARK: - Properties

    private let storage = Storage.storage()
    private let profilePhotosPath = "profilePhotos"

    // MARK: - Upload Profile Photo

    /// Uploads a profile photo for the given user.
    /// - Parameters:
    ///   - imageData: The JPEG image data.
    ///   - userId: The user's Firestore document ID.
    /// - Returns: The download URL string of the uploaded photo.
    func uploadProfilePhoto(imageData: Data, userId: String) async throws -> String {
        let ref = storage.reference().child("\(profilePhotosPath)/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()
        return downloadURL.absoluteString
    }

    // MARK: - Delete Profile Photo

    /// Deletes the profile photo for the given user.
    /// - Parameter userId: The user's Firestore document ID.
    func deleteProfilePhoto(userId: String) async throws {
        let ref = storage.reference().child("\(profilePhotosPath)/\(userId).jpg")
        try await ref.delete()
    }
}
