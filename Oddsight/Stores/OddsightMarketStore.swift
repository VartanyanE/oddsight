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

    private var liveMatches: [MatchedMarket] = []
    private var liveSignals: [OddsightSignal] = []

    init(
        kalshiClient: KalshiMarketClient = KalshiMarketClient(),
        polymarketClient: PolymarketMarketClient = PolymarketMarketClient()
    ) {
        self.kalshiClient = kalshiClient
        self.polymarketClient = polymarketClient
    }

    var matches: [MatchedMarket] {
        isUsingSampleFallback ? SampleOddsightData.matches : liveMatches
    }

    var signals: [OddsightSignal] {
        isUsingSampleFallback ? SampleOddsightData.signals : liveSignals
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
            let sortedMarkets = liveMarkets.sorted { $0.volume24h > $1.volume24h }
            let matches = MarketMatcher.matchMarkets(sortedMarkets)
            markets = sortedMarkets
            liveMatches = matches
            liveSignals = SignalBuilder.buildSignals(for: matches)
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
