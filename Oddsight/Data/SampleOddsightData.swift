import Foundation

enum SampleOddsightData {
    static let kalshiFed = Market(
        id: "kalshi-fed-september-cut",
        title: "Fed cuts rates in September?",
        normalizedQuestion: "Will the Federal Reserve cut the target federal funds rate at the September meeting?",
        platform: .kalshi,
        category: .economics,
        probability: 0.41,
        bestBid: 0.40,
        bestAsk: 0.43,
        noBestBid: 0.57,
        noBestAsk: 0.60,
        volume24h: 820000,
        liquidity: 340000,
        probabilityChange24h: 0.06,
        expirationDescription: "Sep 2026 FOMC",
        resolutionSummary: "Resolves against the official Federal Reserve target rate decision for the September meeting.",
        sourceURL: "https://kalshi.com"
    )

    static let polymarketFed = Market(
        id: "polymarket-fed-september-cut",
        title: "Fed rate cut by September meeting?",
        normalizedQuestion: "Will the Federal Reserve cut rates at or before the September meeting?",
        platform: .polymarket,
        category: .economics,
        probability: 0.48,
        bestBid: 0.47,
        bestAsk: 0.50,
        noBestBid: 0.49,
        noBestAsk: 0.51,
        volume24h: 690000,
        liquidity: 275000,
        probabilityChange24h: 0.02,
        expirationDescription: "Sep 2026 FOMC",
        resolutionSummary: "Resolution wording must be reviewed because the measurement window may differ from the Kalshi market.",
        sourceURL: "https://polymarket.com"
    )

    static let kalshiBitcoin = Market(
        id: "kalshi-btc-150k-2026",
        title: "Bitcoin above $150K at end of 2026?",
        normalizedQuestion: "Will Bitcoin be above 150,000 USD at the end of 2026?",
        platform: .kalshi,
        category: .crypto,
        probability: 0.29,
        bestBid: 0.28,
        bestAsk: 0.31,
        noBestBid: 0.69,
        noBestAsk: 0.72,
        volume24h: 410000,
        liquidity: 190000,
        probabilityChange24h: -0.04,
        expirationDescription: "Dec 31, 2026",
        resolutionSummary: "Requires verification of price source and exact settlement timestamp before cross-market arbitrage labeling.",
        sourceURL: "https://kalshi.com"
    )

    static let polymarketBitcoin = Market(
        id: "polymarket-btc-150k-2026",
        title: "BTC price > $150K at the end of 2026?",
        normalizedQuestion: "Will Bitcoin trade above 150,000 USD at the end of 2026?",
        platform: .polymarket,
        category: .crypto,
        probability: 0.34,
        bestBid: 0.33,
        bestAsk: 0.36,
        noBestBid: 0.64,
        noBestAsk: 0.67,
        volume24h: 525000,
        liquidity: 225000,
        probabilityChange24h: 0.08,
        expirationDescription: "Dec 31, 2026",
        resolutionSummary: "Likely similar event wording, but settlement source and timezone need review.",
        sourceURL: "https://polymarket.com"
    )

    static let politicsMarket = Market(
        id: "kalshi-election-turnout",
        title: "US voter turnout above 65%?",
        normalizedQuestion: "Will United States voter turnout exceed 65 percent in the next general election?",
        platform: .kalshi,
        category: .politics,
        probability: 0.57,
        bestBid: 0.55,
        bestAsk: 0.59,
        noBestBid: 0.41,
        noBestAsk: 0.45,
        volume24h: 120000,
        liquidity: 86000,
        probabilityChange24h: 0.01,
        expirationDescription: "Nov 2026",
        resolutionSummary: "Resolves using official turnout data after certification.",
        sourceURL: "https://kalshi.com"
    )

    static let fedMatch = MatchedMarket(
        id: "match-fed-september-cut",
        primaryMarket: kalshiFed,
        comparisonMarket: polymarketFed,
        confidence: 0.82,
        status: "Possible Match"
    )

    static let bitcoinMatch = MatchedMarket(
        id: "match-btc-150k-2026",
        primaryMarket: kalshiBitcoin,
        comparisonMarket: polymarketBitcoin,
        confidence: 0.88,
        status: "High Confidence"
    )

    static let markets: [Market] = [
        kalshiFed,
        polymarketFed,
        kalshiBitcoin,
        polymarketBitcoin,
        politicsMarket
    ]

    static let matches: [MatchedMarket] = [fedMatch, bitcoinMatch]

    static var signals: [OddsightSignal] {
        let fedDifference = fedMatch.probabilityDifference.pointsText
        let fedArbitrage = fedMatch.potentialArbitrage

        return [
        OddsightSignal(
            id: "signal-fed-discrepancy",
            type: .crossMarketDiscrepancy,
            title: "Fed cut markets differ by \(fedDifference)",
            market: kalshiFed,
            matchedMarket: fedMatch,
            severity: .high,
            confidence: 0.74,
            metricLabel: "Difference",
            metricValue: fedDifference,
            explanation: "Kalshi implies 41% while Polymarket implies 48%. Match remains possible because the exact measurement window may differ.",
            detectedDescription: "4 min ago"
        ),
        OddsightSignal(
            id: "signal-fed-potential-arbitrage",
            type: .potentialArbitrage,
            title: "Fed match has a theoretical price gap",
            market: kalshiFed,
            matchedMarket: fedMatch,
            severity: .high,
            confidence: 0.70,
            metricLabel: "Gross Return",
            metricValue: fedArbitrage?.grossReturn.percentText ?? "Unavailable",
            explanation: "A Kalshi YES ask and Polymarket NO ask combine below $1 in sample data. This remains theoretical until fees, liquidity, and settlement equivalence are verified.",
            detectedDescription: "6 min ago"
        ),
        OddsightSignal(
            id: "signal-btc-move",
            type: .probabilityMove,
            title: "BTC $150K probability moved sharply",
            market: polymarketBitcoin,
            matchedMarket: bitcoinMatch,
            severity: .medium,
            confidence: 0.81,
            metricLabel: "24h Move",
            metricValue: "+8 pts",
            explanation: "The probability increased from 26% to 34% over the last 24 hours in sample data.",
            detectedDescription: "12 min ago"
        ),
        OddsightSignal(
            id: "signal-fed-volume",
            type: .volumeSpike,
            title: "Fed decision volume above baseline",
            market: kalshiFed,
            matchedMarket: nil,
            severity: .medium,
            confidence: 0.68,
            metricLabel: "24h Volume",
            metricValue: "$820K",
            explanation: "Sample volume is elevated relative to other economics markets. Real baseline detection will require stored historical snapshots.",
            detectedDescription: "18 min ago"
        )
        ]
    }
}
