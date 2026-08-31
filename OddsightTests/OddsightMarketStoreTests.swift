import Foundation
import Testing
@testable import Oddsight

@MainActor
struct OddsightMarketStoreTests {
    @Test func deliversTriggeredAlertOnlyOnce() async {
        let market = TestMarket.make(id: "k", title: "Kalshi market", platform: .kalshi, category: .other)
        let alert = MarketAlert(
            id: UUID(),
            marketID: market.id,
            marketTitle: market.title,
            platform: market.platform,
            direction: .risesAbove,
            threshold: 0.45,
            isEnabled: true,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            triggeredAt: nil,
            latestProbability: nil,
            notificationDeliveredAt: nil
        )
        let notificationSpy = NotificationSpy()
        let store = OddsightMarketStore(
            kalshiClient: StubProvider(result: .success([market])),
            polymarketClient: StubProvider(result: .success([])),
            snapshotRepository: StubSnapshotRepository(),
            alertRepository: StubAlertRepository(alerts: [alert]),
            notificationService: notificationSpy
        )

        await store.loadAlerts()
        await store.refreshMarkets()
        await store.refreshMarkets()

        #expect(await notificationSpy.deliveredAlertIDs == [alert.id])
        #expect(store.alerts[0].notificationDeliveredAt != nil)
    }

    @Test func loadsStoredHistoryForMarketDetail() async {
        let observedAt = Date(timeIntervalSince1970: 2_000_000)
        let snapshot = MarketSnapshot(marketID: "k", probability: 0.42, observedAt: observedAt)
        let store = OddsightMarketStore(
            kalshiClient: StubProvider(result: .success([])),
            polymarketClient: StubProvider(result: .success([])),
            snapshotRepository: StubSnapshotRepository(snapshots: [snapshot])
        )

        await store.loadHistory(for: "k")

        #expect(store.snapshotHistory["k"] == [snapshot])
        #expect(store.historyErrors["k"] == nil)
    }

    @Test func combinesSuccessfulProviderResults() async {
        let kalshiMarket = TestMarket.make(id: "k", title: "Kalshi market", platform: .kalshi, category: .other)
        let polymarketMarket = TestMarket.make(id: "p", title: "Polymarket market", platform: .polymarket, category: .other)
        let store = OddsightMarketStore(
            kalshiClient: StubProvider(result: .success([kalshiMarket])),
            polymarketClient: StubProvider(result: .success([polymarketMarket])),
            snapshotRepository: StubSnapshotRepository()
        )

        await store.refreshMarkets()

        #expect(store.dataSourceState == .live)
        #expect(Set(store.markets.map(\.id)) == ["k", "p"])
        #expect(store.errorMessage == nil)
    }

    @Test func preservesSuccessfulMarketsDuringPartialFailure() async {
        let market = TestMarket.make(id: "k", title: "Kalshi market", platform: .kalshi, category: .other)
        let store = OddsightMarketStore(
            kalshiClient: StubProvider(result: .success([market])),
            polymarketClient: StubProvider(result: .failure(StubError.offline)),
            snapshotRepository: StubSnapshotRepository()
        )

        await store.refreshMarkets()

        #expect(store.dataSourceState == .partial(failedProviders: [.polymarket]))
        #expect(store.markets.map(\.id) == ["k"])
        #expect(store.errorMessage?.contains("Polymarket") == true)
        #expect(!store.isUsingSampleFallback)
    }

    @Test func fallsBackToSamplesWhenBothProvidersFail() async {
        let store = OddsightMarketStore(
            kalshiClient: StubProvider(result: .failure(StubError.offline)),
            polymarketClient: StubProvider(result: .failure(StubError.offline)),
            snapshotRepository: StubSnapshotRepository()
        )

        await store.refreshMarkets()

        #expect(store.dataSourceState == .sampleFallback(failedProviders: [.kalshi, .polymarket]))
        #expect(store.isUsingSampleFallback)
        #expect(!store.markets.isEmpty)
    }
}

private struct StubSnapshotRepository: MarketSnapshotRepository {
    let movements: [MarketMovement] = []
    var snapshots: [MarketSnapshot] = []

    func record(markets: [Market], at observedAt: Date) async throws -> [MarketMovement] {
        movements
    }

    func snapshots(for marketID: String) async throws -> [MarketSnapshot] {
        snapshots.filter { $0.marketID == marketID }
    }
}

private struct StubAlertRepository: MarketAlertRepository {
    let alerts: [MarketAlert]

    func load() async throws -> [MarketAlert] { alerts }
    func save(_ alerts: [MarketAlert]) async throws {}
}

private actor NotificationSpy: AlertNotificationDelivering {
    private(set) var deliveredAlertIDs: [UUID] = []

    func authorizationStatus() async -> AlertNotificationAuthorization { .authorized }
    func requestAuthorization() async throws -> Bool { true }
    func deliver(alert: MarketAlert) async throws {
        deliveredAlertIDs.append(alert.id)
    }
}

private struct StubProvider: PredictionMarketProvider {
    let result: Result<[Market], StubError>

    nonisolated func fetchActiveMarkets(limit: Int) async throws -> [Market] {
        Array(try result.get().prefix(limit))
    }
}

private enum StubError: LocalizedError {
    case offline

    var errorDescription: String? { "Provider is offline." }
}
