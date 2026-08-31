import UIKit
import UserNotifications

final class OddsightAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @MainActor private static var pendingAlertID: UUID?

    @MainActor
    static func consumePendingAlertID() -> UUID? {
        defer { pendingAlertID = nil }
        return pendingAlertID
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let alertID = NotificationRoute.alertID(from: response.notification.request.content.userInfo) else { return }
        await MainActor.run {
            Self.pendingAlertID = alertID
            NotificationCenter.default.post(
                name: .oddsightDidOpenAlert,
                object: nil,
                userInfo: [NotificationRoute.alertIDKey: alertID]
            )
        }
    }
}
