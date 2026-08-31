import Foundation

protocol PredictionMarketProvider: Sendable {
    nonisolated func fetchActiveMarkets(limit: Int) async throws -> [Market]
}

extension KalshiMarketClient: PredictionMarketProvider {}
extension PolymarketMarketClient: PredictionMarketProvider {}
