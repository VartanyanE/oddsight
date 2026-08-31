import Foundation
import UserNotifications

enum AlertNotificationAuthorization: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized

    var displayName: String {
        switch self {
        case .notDetermined: "Not configured"
        case .denied: "Disabled in Settings"
        case .authorized: "Enabled"
        }
    }
}

protocol AlertNotificationDelivering: Sendable {
    func authorizationStatus() async -> AlertNotificationAuthorization
    func requestAuthorization() async throws -> Bool
    func deliver(alert: MarketAlert) async throws
}

struct LocalAlertNotificationService: AlertNotificationDelivering {
    func authorizationStatus() async -> AlertNotificationAuthorization {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    func deliver(alert: MarketAlert) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Oddsight alert"
        content.body = "A saved probability alert was triggered. Open Oddsight to review it."
        content.sound = .default
        content.userInfo = [NotificationRoute.alertIDKey: alert.id.uuidString]

        let request = UNNotificationRequest(
            identifier: "oddsight-alert-\(alert.id.uuidString)",
            content: content,
            trigger: nil
        )
        try await UNUserNotificationCenter.current().add(request)
    }
}
