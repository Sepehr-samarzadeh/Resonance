//  ServiceContainer.swift
//  Resonance

import SwiftUI
import FirebaseCore
import FirebaseAppCheck

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
    let discoveryService: any DiscoveryServiceProtocol

    /// Returns `true` when the process is hosted by XCTest / Swift Testing.
    nonisolated static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    init() {
        // Firebase must be configured before any service accesses
        // Firestore or Auth.
        Self.ensureFirebaseConfigured()

        authService = AuthService()
        userService = UserService()
        musicService = MusicService()
        matchService = MatchService()
        chatService = ChatService()
        notificationService = NotificationService()
        storageService = StorageService()
        discoveryService = DiscoveryService()
    }

    // MARK: - Firebase Configuration

    nonisolated(unsafe) private static var firebaseConfigured = false

    /// Ensures `FirebaseApp.configure()` is called exactly once.
    /// In test environments, configures with a dummy project to avoid crashes.
    private static func ensureFirebaseConfigured() {
        guard !firebaseConfigured else { return }
        firebaseConfigured = true

        // App Check must be set BEFORE FirebaseApp.configure().
        // Use the debug provider for all debug builds (simulator + device).
        // App Attest is only used in release builds distributed via the App Store.
        #if DEBUG
        let providerFactory = AppCheckDebugProviderFactory()
        #else
        let providerFactory = ResonanceAppCheckProviderFactory()
        #endif
        AppCheck.setAppCheckProviderFactory(providerFactory)

        if isRunningTests {
            // Provide a minimal configuration so Firestore/Auth/Storage
            // don't crash at init, even though they'll never hit the network.
            let options = FirebaseOptions(
                googleAppID: "1:000000000000:ios:0000000000000000",
                gcmSenderID: "000000000000"
            )
            options.projectID = "resonance-test"
            options.apiKey = "fake-api-key"
            options.storageBucket = "resonance-test.appspot.com"
            FirebaseApp.configure(options: options)
        } else {
            FirebaseApp.configure()
        }
    }
}

// MARK: - Environment Entry

/// Uses `@Entry` macro for environment values (iOS 18+).
extension EnvironmentValues {
    @Entry var services: ServiceContainer = ServiceContainer()
}

// MARK: - App Check Provider Factory

/// Returns an `AppAttestProvider` for each Firebase app.
/// Used on real devices to attest that requests come from the genuine app.
final class ResonanceAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> (any AppCheckProvider)? {
        AppAttestProvider(app: app)
    }
}
