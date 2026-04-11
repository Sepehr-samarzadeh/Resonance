//  MockNotificationService.swift
//  ResonanceTests

import Foundation
@testable import Resonance

final class MockNotificationService: NotificationServiceProtocol, @unchecked Sendable {

    // MARK: - Call Tracking

    var registerDeviceTokenCallCount = 0
    var removeDeviceTokenCallCount = 0

    // MARK: - Stubbed Results

    var stubbedRegisterDeviceTokenError: Error?
    var stubbedRemoveDeviceTokenError: Error?

    // MARK: - Captured Values

    var capturedToken: String?
    var capturedUserId: String?

    // MARK: - Protocol Methods

    func registerDeviceToken(_ token: String, forUserId userId: String) async throws {
        registerDeviceTokenCallCount += 1
        capturedToken = token
        capturedUserId = userId
        if let error = stubbedRegisterDeviceTokenError { throw error }
    }

    func removeDeviceToken(forUserId userId: String) async throws {
        removeDeviceTokenCallCount += 1
        capturedUserId = userId
        if let error = stubbedRemoveDeviceTokenError { throw error }
    }
}
