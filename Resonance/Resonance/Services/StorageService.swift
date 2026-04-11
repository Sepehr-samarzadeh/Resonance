//  StorageService.swift
//  Resonance

import Foundation
import OSLog
@preconcurrency import FirebaseStorage

// MARK: - StorageService

actor StorageService: StorageServiceProtocol {

    // MARK: - Properties

    /// Storage instance — resolved lazily to ensure Firebase is configured first.
    private var storage: Storage {
        Storage.storage()
    }
    private let profilePhotosPath = "profilePhotos"
    private nonisolated let logger = Logger(subsystem: "com.resonance", category: "storage")

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

        logger.info("Uploading profile photo for user \(userId), size: \(imageData.count) bytes")

        let resultMetadata: StorageMetadata
        do {
            resultMetadata = try await ref.putDataAsync(imageData, metadata: metadata)
            logger.info("Upload succeeded, path: \(resultMetadata.path ?? "nil"), size: \(resultMetadata.size)")
        } catch {
            logger.error("Upload failed: \(error.localizedDescription)")
            throw error
        }

        do {
            let downloadURL = try await ref.downloadURL()
            logger.info("Got download URL: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            logger.error("downloadURL() failed: \(error.localizedDescription). Constructing URL manually.")
            // Fallback: construct the download URL from the storage bucket and path
            let bucket = ref.bucket
            let encodedPath = "\(profilePhotosPath)/\(userId).jpg"
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let fallbackURL = "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/\(encodedPath)?alt=media"
            return fallbackURL
        }
    }

    // MARK: - Delete Profile Photo

    /// Deletes the profile photo for the given user.
    /// - Parameter userId: The user's Firestore document ID.
    func deleteProfilePhoto(userId: String) async throws {
        let ref = storage.reference().child("\(profilePhotosPath)/\(userId).jpg")
        try await ref.delete()
    }
}
