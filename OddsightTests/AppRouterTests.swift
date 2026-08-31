import Foundation
import Testing
@testable import Oddsight

struct AppRouterTests {
    @Test func parsesAlertIdentifierFromNotificationPayload() {
        let expected = UUID(uuidString: "00000000-0000-0000-0000-000000000123")!

        let parsed = NotificationRoute.alertID(from: [
            NotificationRoute.alertIDKey: expected.uuidString
        ])

        #expect(parsed == expected)
        #expect(NotificationRoute.alertID(from: [:]) == nil)
        #expect(NotificationRoute.alertID(from: [NotificationRoute.alertIDKey: "invalid"]) == nil)
    }

    @Test @MainActor func openingAlertSelectsTabAndCreatesConsumableRoute() {
        let router = AppRouter()
        let alertID = UUID()

        router.openAlert(alertID)

        #expect(router.selectedTab == .alerts)
        #expect(router.pendingAlertID == alertID)
        #expect(router.consumePendingAlert() == alertID)
        #expect(router.pendingAlertID == nil)
    }
}
