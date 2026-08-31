import Testing
@testable import Oddsight

struct EntitlementTests {
    @Test func planConfigurationControlsFeatureAccess() {
        let configuration = EntitlementConfiguration(plans: [
            .free: PlanEntitlements(alertLimit: 1, scannerSignalLimit: 2, supportsAdvancedScanner: false)
        ])

        let entitlements = configuration.entitlements(for: .free)

        #expect(entitlements.canCreateAlert(existingCount: 0))
        #expect(!entitlements.canCreateAlert(existingCount: 1))
        #expect(entitlements.scannerSignalLimit == 2)
        #expect(!entitlements.supportsAdvancedScanner)
    }

    @Test @MainActor func storeEnforcesConfiguredAlertLimit() async {
        let configuration = EntitlementConfiguration(plans: [
            .free: PlanEntitlements(alertLimit: 1, scannerSignalLimit: nil, supportsAdvancedScanner: false)
        ])
        let store = OddsightMarketStore(
            alertRepository: MemoryAlertRepository(),
            currentTier: .free,
            entitlementConfiguration: configuration
        )
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)

        let firstWasAdded = await store.addAlert(for: market, direction: .risesAbove, threshold: 0.60)
        let secondWasAdded = await store.addAlert(for: market, direction: .fallsBelow, threshold: 0.40)

        #expect(firstWasAdded)
        #expect(!secondWasAdded)
        #expect(store.alerts.count == 1)
        #expect(store.entitlementMessage != nil)
    }

    @Test @MainActor func storeLimitsScannerResultsByPlan() {
        let configuration = EntitlementConfiguration(plans: [
            .free: PlanEntitlements(alertLimit: 1, scannerSignalLimit: 1, supportsAdvancedScanner: false)
        ])
        let store = OddsightMarketStore(currentTier: .free, entitlementConfiguration: configuration)

        #expect(store.signals.count == min(1, SampleOddsightData.signals.count))
    }
}

private actor MemoryAlertRepository: MarketAlertRepository {
    private var alerts: [MarketAlert] = []

    func load() -> [MarketAlert] { alerts }
    func save(_ alerts: [MarketAlert]) { self.alerts = alerts }
}
