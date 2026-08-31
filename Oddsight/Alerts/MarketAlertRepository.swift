import Foundation

enum ProbabilityAlertDirection: String, Codable, CaseIterable, Identifiable, Sendable {
    case risesAbove
    case fallsBelow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .risesAbove: "Rises above"
        case .fallsBelow: "Falls below"
        }
    }

    nonisolated func isTriggered(by probability: Double, threshold: Double) -> Bool {
        switch self {
        case .risesAbove: probability >= threshold
        case .fallsBelow: probability <= threshold
        }
    }
}

struct MarketAlert: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let marketID: String
    let marketTitle: String
    let platform: PredictionPlatform
    let direction: ProbabilityAlertDirection
    let threshold: Double
    var isEnabled: Bool
    let createdAt: Date
    var triggeredAt: Date?
    var latestProbability: Double?
    var notificationDeliveredAt: Date?

    var isTriggered: Bool { triggeredAt != nil }
}

protocol MarketAlertRepository: Sendable {
    func load() async throws -> [MarketAlert]
    func save(_ alerts: [MarketAlert]) async throws
}

actor LocalMarketAlertRepository: MarketAlertRepository {
    private let fileURL: URL

    init(fileURL: URL = LocalMarketAlertRepository.defaultFileURL()) {
        self.fileURL = fileURL
    }

    func load() throws -> [MarketAlert] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([MarketAlert].self, from: Data(contentsOf: fileURL))
    }

    func save(_ alerts: [MarketAlert]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(alerts).write(to: fileURL, options: .atomic)
    }

    nonisolated static func defaultFileURL() -> URL {
        URL.applicationSupportDirectory
            .appending(path: "Oddsight", directoryHint: .isDirectory)
            .appending(path: "market-alerts.json")
    }
}

enum MarketAlertEvaluator {
    nonisolated static func evaluate(
        _ alerts: [MarketAlert],
        markets: [Market],
        at evaluatedAt: Date
    ) -> [MarketAlert] {
        let marketsByID = Dictionary(uniqueKeysWithValues: markets.map { ($0.id, $0) })
        return alerts.map { alert in
            guard alert.isEnabled, let market = marketsByID[alert.marketID] else { return alert }
            var updated = alert
            updated.latestProbability = market.probability
            if alert.triggeredAt == nil,
               alert.direction.isTriggered(by: market.probability, threshold: alert.threshold) {
                updated.triggeredAt = evaluatedAt
            }
            return updated
        }
    }
}
