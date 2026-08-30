import Foundation
import Observation

@Observable
@MainActor
final class OddsightMarketStore {
    private let kalshiClient: KalshiMarketClient
    private let polymarketClient: PolymarketMarketClient

    var markets: [Market] = SampleOddsightData.markets
    var isLoading = false
    var errorMessage: String?
    var lastUpdatedAt: Date?
    var isUsingSampleFallback = true

    init(
        kalshiClient: KalshiMarketClient = KalshiMarketClient(),
        polymarketClient: PolymarketMarketClient = PolymarketMarketClient()
    ) {
        self.kalshiClient = kalshiClient
        self.polymarketClient = polymarketClient
    }

    var matches: [MatchedMarket] {
        SampleOddsightData.matches
    }

    var signals: [OddsightSignal] {
        SampleOddsightData.signals
    }

    func refreshMarkets() async {
        isLoading = true
        errorMessage = nil

        var liveMarkets: [Market] = []
        var providerErrors: [String] = []

        do {
            liveMarkets.append(contentsOf: try await kalshiClient.fetchActiveMarkets())
        } catch {
            providerErrors.append("Kalshi: \(error.localizedDescription)")
        }

        do {
            liveMarkets.append(contentsOf: try await polymarketClient.fetchActiveMarkets())
        } catch {
            providerErrors.append("Polymarket: \(error.localizedDescription)")
        }

        if liveMarkets.isEmpty {
            errorMessage = providerErrors.isEmpty ? "Providers returned no active binary markets. Showing sample data." : providerErrors.joined(separator: " ")
            isUsingSampleFallback = true
        } else {
            markets = liveMarkets.sorted { $0.volume24h > $1.volume24h }
            lastUpdatedAt = Date()
            isUsingSampleFallback = false
            errorMessage = providerErrors.isEmpty ? nil : providerErrors.joined(separator: " ")
        }

        isLoading = false
    }

    func matchedMarket(for market: Market) -> MatchedMarket? {
        matches.first { match in
            match.primaryMarket.id == market.id || match.comparisonMarket.id == market.id
        }
    }
}
