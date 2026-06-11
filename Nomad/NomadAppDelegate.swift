//
//  NomadAppDelegate.swift
//  Nomad
//

import UIKit
import CloudKit
import UserNotifications

final class NomadAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    static let didReceivePostcardNotification = Notification.Name("NomadDidReceivePostcard")

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        // Only register for remote notifications if CloudKit is enabled —
        // otherwise we get push entitlement errors in local test builds.
        if UserDefaults.standard.bool(forKey: "nomad.cloudKitEnabled") {
            application.registerForRemoteNotifications()
        }
        Task {
            try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        }
        return true
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return .noData
        }
        if notification.subscriptionID?.hasPrefix("nomad.receive.") == true {
            NotificationCenter.default.post(name: Self.didReceivePostcardNotification, object: nil)
            return .newData
        }
        return .noData
    }
}
