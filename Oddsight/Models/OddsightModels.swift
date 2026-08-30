import Foundation
import SwiftUI

enum PredictionPlatform: String, CaseIterable, Identifiable {
    case kalshi = "Kalshi"
    case polymarket = "Polymarket"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .kalshi:
            return .blue
        case .polymarket:
            return .green
        }
    }
}

enum MarketCategory: String, CaseIterable, Identifiable {
    case politics = "Politics"
    case economics = "Economics"
    case crypto = "Crypto"
    case technology = "Technology"
    case sports = "Sports"
    case weather = "Weather"
    case entertainment = "Entertainment"
    case worldEvents = "World Events"
    case other = "Other"

    var id: String { rawValue }
}

enum SignalType: String, CaseIterable, Identifiable {
    case crossMarketDiscrepancy = "Cross-Market Discrepancy"
    case potentialArbitrage = "Potential Arbitrage"
    case probabilityMove = "Probability Move"
    case volumeSpike = "Volume Spike"
    case liquidityChange = "Liquidity Change"

    var id: String { rawValue }
}

enum SignalSeverity: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var tint: Color {
        switch self {
        case .low:
            return .secondary
        case .medium:
            return .yellow
        case .high:
            return .orange
        case .critical:
            return .red
        }
    }
}

struct Market: Identifiable, Hashable {
    let id: String
    let title: String
    let normalizedQuestion: String
    let platform: PredictionPlatform
    let category: MarketCategory
    let probability: Double
    let bestBid: Double?
    let bestAsk: Double?
    let noBestBid: Double?
    let noBestAsk: Double?
    let volume24h: Double
    let liquidity: Double
    let probabilityChange24h: Double
    let expirationDescription: String
    let resolutionSummary: String
    let sourceURL: String

    nonisolated var quote: BinaryMarketQuote {
        let fallbackMidpoint = bestBid.flatMap { bid in
            bestAsk.map { ask in
                (bid + ask) / 2
            }
        }

        return (try? MarketCalculations.directQuote(
            yesBid: bestBid,
            yesAsk: bestAsk,
            noBid: noBestBid,
            noAsk: noBestAsk,
            lastTradePrice: probability,
            midpoint: fallbackMidpoint
        )) ?? BinaryMarketQuote(
            yesBid: nil,
            yesAsk: nil,
            noBid: nil,
            noAsk: nil,
            lastTradePrice: nil,
            midpoint: nil,
            sourceQuality: .unavailable
        )
    }
}

struct MatchedMarket: Identifiable, Hashable {
    let id: String
    let primaryMarket: Market
    let comparisonMarket: Market
    let confidence: Double
    let status: String
    let assessment: MatchAssessment

    nonisolated var discrepancy: CrossMarketDiscrepancy? {
        try? MarketCalculations.discrepancy(between: primaryMarket.quote, and: comparisonMarket.quote)
    }

    nonisolated var probabilityDifference: Double {
        discrepancy?.absoluteDifference ?? abs(primaryMarket.probability - comparisonMarket.probability)
    }

    nonisolated var potentialArbitrage: PotentialArbitrage? {
        try? MarketCalculations.potentialArbitrage(
            yesAsk: primaryMarket.quote.yesAsk,
            noAsk: comparisonMarket.quote.noAsk
        )
    }
}

struct MatchAssessment: Hashable {
    let eventSimilarity: Double
    let categoryCompatible: Bool
    let expirationSimilarity: Double
    let sharedTerms: [String]
    let reasons: [String]
    let risks: [String]
    let generatedBy: String
}

struct OddsightSignal: Identifiable, Hashable {
    let id: String
    let type: SignalType
    let title: String
    let market: Market
    let matchedMarket: MatchedMarket?
    let severity: SignalSeverity
    let confidence: Double
    let metricLabel: String
    let metricValue: String
    let explanation: String
    let detectedDescription: String
}
