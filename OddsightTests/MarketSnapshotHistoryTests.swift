import Foundation
import Testing
@testable import Oddsight

struct MarketSnapshotHistoryTests {
    @Test func localRepositoryReturnsChronologicalMarketHistory() async throws {
        let fileURL = FileManager.default.temporaryDirectory
            .appending(path: "oddsight-history-\(UUID().uuidString).json")
        let repository = LocalMarketSnapshotRepository(fileURL: fileURL)
        let later = Date(timeIntervalSince1970: 2_000_000)
        let earlier = later.addingTimeInterval(-3_600)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)

        _ = try await repository.record(markets: [market], at: later)
        _ = try await repository.record(markets: [market], at: earlier)
        let snapshots = try await repository.snapshots(for: market.id)

        #expect(snapshots.map(\.observedAt) == [earlier, later])
        #expect(try await repository.snapshots(for: "another-market").isEmpty)
        try? FileManager.default.removeItem(at: fileURL)
    }

    @Test func calculatesOneHourAndTwentyFourHourMovements() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)
        let history = [
            MarketSnapshot(marketID: market.id, probability: 0.30, observedAt: now.addingTimeInterval(-25 * 60 * 60)),
            MarketSnapshot(marketID: market.id, probability: 0.42, observedAt: now.addingTimeInterval(-75 * 60))
        ]

        let movements = MarketSnapshotHistory.movements(for: [market], history: history, at: now)

        #expect(movements.count == 2)
        #expect(abs((movements.first(where: { $0.window == .oneHour })?.change ?? 0) - 0.08) < 0.000_001)
        #expect(abs((movements.first(where: { $0.window == .twentyFourHours })?.change ?? 0) - 0.20) < 0.000_001)
    }

    @Test func doesNotInventMovementWithoutOldEnoughObservation() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)
        let history = [
            MarketSnapshot(marketID: market.id, probability: 0.48, observedAt: now.addingTimeInterval(-30 * 60))
        ]

        #expect(MarketSnapshotHistory.movements(for: [market], history: history, at: now).isEmpty)
    }

    @Test func prunesSnapshotsOutsideRetentionWindow() {
        let now = Date(timeIntervalSince1970: 4_000_000)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)
        let expired = MarketSnapshot(
            marketID: market.id,
            probability: 0.20,
            observedAt: now.addingTimeInterval(-MarketSnapshotHistory.retentionDuration - 1)
        )

        let updated = MarketSnapshotHistory.appending(markets: [market], to: [expired], at: now)

        #expect(updated.count == 1)
        #expect(updated[0].observedAt == now)
    }

    @Test func movementSignalRequiresFivePointThreshold() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let market = TestMarket.make(id: "market", title: "Will it happen?", platform: .kalshi, category: .other)
        let small = MarketMovement(
            marketID: market.id,
            window: .oneHour,
            previousProbability: 0.46,
            currentProbability: 0.50,
            previousObservedAt: now.addingTimeInterval(-3_600),
            currentObservedAt: now
        )
        let material = MarketMovement(
            marketID: market.id,
            window: .twentyFourHours,
            previousProbability: 0.40,
            currentProbability: 0.50,
            previousObservedAt: now.addingTimeInterval(-86_400),
            currentObservedAt: now
        )

        let signals = SignalBuilder.movementSignals(from: [small, material], markets: [market])

        #expect(signals.count == 1)
        #expect(signals[0].type == .probabilityMove)
        #expect(signals[0].metricValue == "+10 pts")
    }
}
