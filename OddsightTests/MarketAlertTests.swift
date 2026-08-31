import Foundation
import Testing
@testable import Oddsight

struct MarketAlertTests {
    @Test func evaluatorTriggersEnabledThresholdOnce() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)
        let alert = makeAlert(direction: .risesAbove, threshold: 0.45)

        let evaluated = MarketAlertEvaluator.evaluate([alert], markets: [market], at: now)

        #expect(evaluated[0].triggeredAt == now)
        #expect(evaluated[0].latestProbability == market.probability)
    }

    @Test func evaluatorLeavesPausedAlertUntouched() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        var alert = makeAlert(direction: .fallsBelow, threshold: 0.60)
        alert.isEnabled = false

        let evaluated = MarketAlertEvaluator.evaluate(
            [alert],
            markets: [TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)],
            at: now
        )

        #expect(evaluated == [alert])
    }

    @Test func localRepositoryRoundTripsAlerts() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "oddsight-alerts-\(UUID().uuidString).json")
        let repository = LocalMarketAlertRepository(fileURL: fileURL)
        let alerts = [makeAlert(direction: .risesAbove, threshold: 0.65)]

        try await repository.save(alerts)
        let loaded = try await repository.load()

        #expect(loaded == alerts)
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func makeAlert(
        direction: ProbabilityAlertDirection,
        threshold: Double
    ) -> MarketAlert {
        MarketAlert(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            marketID: "market",
            marketTitle: "Will it happen?",
            platform: .kalshi,
            direction: direction,
            threshold: threshold,
            isEnabled: true,
            createdAt: Date(timeIntervalSince1970: 1_000_000),
            triggeredAt: nil,
            latestProbability: nil,
            notificationDeliveredAt: nil
        )
    }
}
