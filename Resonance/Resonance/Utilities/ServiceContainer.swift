//  ServiceContainer.swift
//  Resonance

import SwiftUI

// MARK: - ServiceContainer

/// Holds all shared service instances for the app.
/// Created once at app launch and injected via SwiftUI Environment.
final class ServiceContainer: Sendable {
    let authService: any AuthServiceProtocol
    let userService: any UserServiceProtocol
    let musicService: any MusicServiceProtocol
    let matchService: any MatchServiceProtocol
    let chatService: any ChatServiceProtocol
    let notificationService: any NotificationServiceProtocol
    let storageService: any StorageServiceProtocol

    init() {
        authService = AuthService()
        userService = UserService()
        musicService = MusicService()
        matchService = MatchService()
        chatService = ChatService()
        notificationService = NotificationService()
        storageService = StorageService()
    }
}

// MARK: - Environment Entry

private struct ServicesKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = ServiceContainer()
}

extension EnvironmentValues {
    var services: ServiceContainer {
        get { self[ServicesKey.self] }
        set { self[ServicesKey.self] = newValue }
    }
}
