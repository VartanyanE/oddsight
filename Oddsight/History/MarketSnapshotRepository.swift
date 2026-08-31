import Foundation

enum MovementWindow: String, Codable, Sendable {
    case oneHour
    case twentyFourHours

    nonisolated var duration: TimeInterval {
        switch self {
        case .oneHour: 60 * 60
        case .twentyFourHours: 24 * 60 * 60
        }
    }

    nonisolated var displayName: String {
        switch self {
        case .oneHour: "1h"
        case .twentyFourHours: "24h"
        }
    }
}

struct MarketSnapshot: Codable, Equatable, Sendable {
    let marketID: String
    let probability: Double
    let observedAt: Date
}

struct MarketMovement: Equatable, Sendable {
    let marketID: String
    let window: MovementWindow
    let previousProbability: Double
    let currentProbability: Double
    let previousObservedAt: Date
    let currentObservedAt: Date

    nonisolated var change: Double { currentProbability - previousProbability }
}

protocol MarketSnapshotRepository: Sendable {
    func record(markets: [Market], at observedAt: Date) async throws -> [MarketMovement]
    func snapshots(for marketID: String) async throws -> [MarketSnapshot]
}

enum MarketSnapshotHistory {
    nonisolated static let retentionDuration: TimeInterval = 30 * 24 * 60 * 60

    nonisolated static func movements(
        for markets: [Market],
        history: [MarketSnapshot],
        at observedAt: Date
    ) -> [MarketMovement] {
        let snapshotsByMarket = Dictionary(grouping: history, by: \.marketID)

        return markets.flatMap { market in
            let snapshots = snapshotsByMarket[market.id] ?? []
            return [MovementWindow.oneHour, .twentyFourHours].compactMap { window in
                movement(for: market, snapshots: snapshots, window: window, at: observedAt)
            }
        }
    }

    nonisolated static func appending(
        markets: [Market],
        to history: [MarketSnapshot],
        at observedAt: Date
    ) -> [MarketSnapshot] {
        let cutoff = observedAt.addingTimeInterval(-retentionDuration)
        let retained = history.filter { $0.observedAt >= cutoff }
        let newSnapshots = markets.compactMap { market -> MarketSnapshot? in
            guard (0...1).contains(market.probability) else { return nil }
            return MarketSnapshot(marketID: market.id, probability: market.probability, observedAt: observedAt)
        }
        return retained + newSnapshots
    }

    private nonisolated static func movement(
        for market: Market,
        snapshots: [MarketSnapshot],
        window: MovementWindow,
        at observedAt: Date
    ) -> MarketMovement? {
        let target = observedAt.addingTimeInterval(-window.duration)
        let maximumAge: TimeInterval = window == .oneHour ? 6 * 60 * 60 : 48 * 60 * 60
        guard let previous = snapshots
            .filter({ $0.observedAt <= target && target.timeIntervalSince($0.observedAt) <= maximumAge })
            .max(by: { $0.observedAt < $1.observedAt }) else {
            return nil
        }

        return MarketMovement(
            marketID: market.id,
            window: window,
            previousProbability: previous.probability,
            currentProbability: market.probability,
            previousObservedAt: previous.observedAt,
            currentObservedAt: observedAt
        )
    }
}

actor LocalMarketSnapshotRepository: MarketSnapshotRepository {
    private let fileURL: URL
    private var cachedSnapshots: [MarketSnapshot]?

    init(fileURL: URL = LocalMarketSnapshotRepository.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func record(markets: [Market], at observedAt: Date) throws -> [MarketMovement] {
        let history = try loadSnapshots()
        let movements = MarketSnapshotHistory.movements(for: markets, history: history, at: observedAt)
        let updated = MarketSnapshotHistory.appending(markets: markets, to: history, at: observedAt)
        try persist(updated)
        cachedSnapshots = updated
        return movements
    }

    func snapshots(for marketID: String) throws -> [MarketSnapshot] {
        try loadSnapshots()
            .filter { $0.marketID == marketID }
            .sorted { $0.observedAt < $1.observedAt }
    }

    nonisolated static func defaultFileURL() -> URL {
        URL.applicationSupportDirectory
            .appending(path: "Oddsight", directoryHint: .isDirectory)
            .appending(path: "market-snapshots.json")
    }

    private func loadSnapshots() throws -> [MarketSnapshot] {
        if let cachedSnapshots { return cachedSnapshots }
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MarketSnapshot].self, from: data)
    }

    private func persist(_ snapshots: [MarketSnapshot]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshots).write(to: fileURL, options: .atomic)
    }
}
