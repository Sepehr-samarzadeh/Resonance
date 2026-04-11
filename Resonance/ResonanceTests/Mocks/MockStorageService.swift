//  MockStorageService.swift
//  ResonanceTests

import Foundation
@testable import Resonance

final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var uploadProfilePhotoCallCount = 0
    var deleteProfilePhotoCallCount = 0

    // MARK: - Stubbed Results

    var stubbedUploadProfilePhotoResult: Result<String, Error> = .success("https://example.com/photo.jpg")
    var stubbedDeleteProfilePhotoError: Error?

    // MARK: - Captured Values

    var capturedImageData: Data?
    var capturedUserId: String?

    // MARK: - Protocol Methods

    func uploadProfilePhoto(imageData: Data, userId: String) async throws -> String {
        uploadProfilePhotoCallCount += 1
        capturedImageData = imageData
        capturedUserId = userId
        return try stubbedUploadProfilePhotoResult.get()
    }

    func deleteProfilePhoto(userId: String) async throws {
        deleteProfilePhotoCallCount += 1
        capturedUserId = userId
        if let error = stubbedDeleteProfilePhotoError { throw error }
    }
}
