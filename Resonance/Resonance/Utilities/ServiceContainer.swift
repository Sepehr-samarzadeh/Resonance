//  ServiceContainer.swift
//  Resonance

import SwiftUI

// MARK: - ServiceContainer

/// Holds all shared service instances for the app.
/// Created once at app launch and injected via SwiftUI Environment.
final class ServiceContainer: Sendable {
    let authService: AuthService
    let userService: UserService
    let musicService: MusicService
    let matchService: MatchService
    let chatService: ChatService
    let notificationService: NotificationService
    let storageService: StorageService

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
