//  AppDelegate.swift
//  Resonance

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UserNotifications

// MARK: - AppDelegate

@Observable
class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {

    // MARK: - Properties

    /// Shared notification service — injected from ServiceContainer after launch.
    var notificationService: NotificationService?

    /// Deep-link that should be navigated to. Set when a notification is tapped.
    /// Observed by `MainTabView` to drive navigation.
    var pendingDeepLink: DeepLink?

    // MARK: - App Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications(application)
        return true
    }

    // MARK: - Google Sign-In URL Handling

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Push Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("AppDelegate: APNs device token — \(tokenString)")

        Task { @MainActor in
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    try await notificationService?.registerDeviceToken(tokenString, forUserId: userId)
                } catch {
                    print("AppDelegate: Failed to register device token — \(error.localizedDescription)")
                }
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("AppDelegate: Failed to register for remote notifications — \(error.localizedDescription)")
    }

    // MARK: - Private

    private func registerForPushNotifications(_ application: UIApplication) {
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    application.registerForRemoteNotifications()
                }
            } catch {
                print("AppDelegate: Notification auth error — \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Called when a notification arrives while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    /// Called when the user taps a notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo

        if let matchId = userInfo["matchId"] as? String {
            await MainActor.run { pendingDeepLink = .chat(matchId: matchId) }
        } else if let type = userInfo["type"] as? String, type == "match" {
            await MainActor.run { pendingDeepLink = .matches }
        }
    }
}

// MARK: - DeepLink

enum DeepLink: Sendable, Equatable {
    case chat(matchId: String)
    case matches
}
