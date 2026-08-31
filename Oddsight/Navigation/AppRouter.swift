import Foundation
import Observation

enum AppTab: Hashable, Sendable {
    case discover
    case scanner
    case markets
    case alerts
    case settings
}

enum NotificationRoute {
    static let alertIDKey = "alertID"

    nonisolated static func alertID(from userInfo: [AnyHashable: Any]) -> UUID? {
        if let id = userInfo[alertIDKey] as? UUID { return id }
        guard let rawValue = userInfo[alertIDKey] as? String else { return nil }
        return UUID(uuidString: rawValue)
    }
}

extension Notification.Name {
    static let oddsightDidOpenAlert = Notification.Name("OddsightDidOpenAlert")
}

@Observable
@MainActor
final class AppRouter {
    var selectedTab: AppTab = .discover
    private(set) var pendingAlertID: UUID?

    func openAlert(_ alertID: UUID) {
        pendingAlertID = alertID
        selectedTab = .alerts
    }

    func consumePendingAlert() -> UUID? {
        defer { pendingAlertID = nil }
        return pendingAlertID
    }
}
