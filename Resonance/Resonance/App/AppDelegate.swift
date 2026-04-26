//  AppDelegate.swift
//  Resonance

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import GoogleSignIn
import UserNotifications
import OSLog

// MARK: - AppDelegate

@Observable
class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {

    // MARK: - Properties

    /// Shared notification service — injected from ServiceContainer after launch.
    var notificationService: (any NotificationServiceProtocol)?

    /// Deep-link that should be navigated to. Set when a notification is tapped.
    /// Observed by `MainTabView` to drive navigation.
    var pendingDeepLink: DeepLink?

    /// Stores the latest FCM registration token for post-sign-in registration.
    var latestDeviceToken: String?

    // MARK: - App Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase is configured by `ServiceContainer.init()`, which runs
        // before this callback. Only set up notifications here.
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Re-register for remote notifications if permission was previously granted
        // (does NOT prompt the user)
        Task { @MainActor in
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            if settings.authorizationStatus == .authorized {
                application.registerForRemoteNotifications()
            }
        }

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
        // Pass the raw APNs token to Firebase Messaging so it can obtain an FCM token.
        Messaging.messaging().apnsToken = deviceToken
        Log.notification.info("APNs device token forwarded to Firebase Messaging")
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Log.notification.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Notification Registration

    /// Requests notification permission and registers for remote notifications.
    /// Called after onboarding, not on launch.
    func requestNotificationPermission() {
        Task { @MainActor in
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } catch {
                Log.notification.error("Notification authorization error: \(error.localizedDescription)")
            }
        }
    }

    /// Registers the FCM token with Firestore for the currently signed-in user.
    fileprivate func registerFCMToken(_ fcmToken: String) {
        latestDeviceToken = fcmToken

        Task { @MainActor in
            if let userId = Auth.auth().currentUser?.uid {
                do {
                    try await notificationService?.registerDeviceToken(fcmToken, forUserId: userId)
                } catch {
                    Log.notification.error("Failed to register FCM token: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - MessagingDelegate

extension AppDelegate: MessagingDelegate {

    /// Called when Firebase Messaging receives a new or refreshed FCM registration token.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Log.notification.info("FCM registration token received")
        registerFCMToken(fcmToken)
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
