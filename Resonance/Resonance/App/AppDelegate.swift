//  AppDelegate.swift
//  Resonance

import Foundation
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {

    // MARK: - Properties

    private let notificationService = NotificationService()

    // MARK: - App Launch

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
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
        let tokenString = notificationService.tokenString(from: deviceToken)
        print("AppDelegate: APNs device token — \(tokenString)")

        Task { @MainActor in
            if let userId = Auth.auth().currentUser?.uid {
                try? await notificationService.registerDeviceToken(tokenString, forUserId: userId)
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("AppDelegate: Notification auth error — \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
}
