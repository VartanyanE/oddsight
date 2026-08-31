import Testing
@testable import Oddsight

struct MarketMatcherTests {
    @Test func aliasesBitcoinTickerForCandidateMatching() {
        let kalshi = TestMarket.make(
            id: "kalshi-btc",
            title: "Will BTC exceed 150000 in December 2026?",
            platform: .kalshi,
            category: .crypto
        )
        let polymarket = TestMarket.make(
            id: "polymarket-bitcoin",
            title: "Will Bitcoin exceed 150000 by December 2026?",
            platform: .polymarket,
            category: .crypto
        )

        let candidates = MarketMatcher.candidateMatches(from: [kalshi, polymarket])

        #expect(candidates.count == 1)
        #expect(candidates[0].sharedTerms.contains("bitcoin"))
    }

    @Test func incompatibleCategoriesDoNotMatch() {
        let politics = TestMarket.make(id: "k", title: "Will Atlas win in 2026?", platform: .kalshi, category: .politics)
        let sports = TestMarket.make(id: "p", title: "Will Atlas win in 2026?", platform: .polymarket, category: .sports)

        #expect(MarketMatcher.candidateMatches(from: [politics, sports]).isEmpty)
    }
}

enum TestMarket {
    static func make(
        id: String,
        title: String,
        platform: PredictionPlatform,
        category: MarketCategory,
        volume24h: Double = 1_000
    ) -> Market {
        Market(
            id: id,
            title: title,
            normalizedQuestion: title,
            platform: platform,
            category: category,
            probability: 0.5,
            bestBid: 0.49,
            bestAsk: 0.51,
            noBestBid: 0.49,
            noBestAsk: 0.51,
            volume24h: volume24h,
            liquidity: 500,
            probabilityChange24h: 0,
            expirationDescription: "December 2026",
            resolutionSummary: "Official result.",
            sourceURL: "https://example.com/\(id)"
        )
    }
}
