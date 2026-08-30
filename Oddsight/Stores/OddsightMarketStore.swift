import Foundation
import Observation

@Observable
@MainActor
final class OddsightMarketStore {
    private let kalshiClient: KalshiMarketClient

    var markets: [Market] = SampleOddsightData.markets
    var isLoading = false
    var errorMessage: String?
    var lastUpdatedAt: Date?
    var isUsingSampleFallback = true

    init(kalshiClient: KalshiMarketClient = KalshiMarketClient()) {
        self.kalshiClient = kalshiClient
    }

    var matches: [MatchedMarket] {
        SampleOddsightData.matches
    }

    var signals: [OddsightSignal] {
        SampleOddsightData.signals
    }

    func refreshKalshiMarkets() async {
        isLoading = true
        errorMessage = nil

        do {
            let liveMarkets = try await kalshiClient.fetchActiveMarkets()
            if liveMarkets.isEmpty {
                errorMessage = "Kalshi returned no active binary markets. Showing sample data."
                isUsingSampleFallback = true
            } else {
                markets = liveMarkets
                lastUpdatedAt = Date()
                isUsingSampleFallback = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isUsingSampleFallback = true
        }

        isLoading = false
    }

    func matchedMarket(for market: Market) -> MatchedMarket? {
        matches.first { match in
            match.primaryMarket.id == market.id || match.comparisonMarket.id == market.id
        }
    }
}
