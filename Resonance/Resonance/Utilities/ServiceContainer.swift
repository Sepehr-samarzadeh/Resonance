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

    init() {
        authService = AuthService()
        userService = UserService()
        musicService = MusicService()
        matchService = MatchService()
        chatService = ChatService()
        notificationService = NotificationService()
    }
}

// MARK: - Environment Entry

extension EnvironmentValues {
    @Entry var services: ServiceContainer = ServiceContainer()
}
