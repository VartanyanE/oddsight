import Foundation

enum SignalBuilder {
    nonisolated static func buildSignals(
        for matches: [MatchedMarket],
        movements: [MarketMovement] = [],
        markets: [Market]? = nil
    ) -> [OddsightSignal] {
        let matchSignals = matches.flatMap { match in
            signals(for: match)
        }
        let movementMarkets = markets ?? matches.flatMap { [$0.primaryMarket, $0.comparisonMarket] }

        return (matchSignals + movementSignals(from: movements, markets: movementMarkets)).sorted { first, second in
            severityRank(first.severity) == severityRank(second.severity)
                ? first.confidence > second.confidence
                : severityRank(first.severity) > severityRank(second.severity)
        }
    }

    nonisolated static func movementSignals(from movements: [MarketMovement], markets: [Market]) -> [OddsightSignal] {
        movementSignals(from: movements, marketLookup: Dictionary(uniqueKeysWithValues: markets.map { ($0.id, $0) }))
    }

    private nonisolated static func movementSignals(
        from movements: [MarketMovement],
        marketLookup: [String: Market]
    ) -> [OddsightSignal] {
        movements.compactMap { movement in
            guard let market = marketLookup[movement.marketID], abs(movement.change) >= 0.05 else {
                return nil
            }
            let magnitude = abs(movement.change)
            return OddsightSignal(
                id: "signal-movement-\(movement.window.rawValue)-\(market.id)-\(Int(movement.currentObservedAt.timeIntervalSince1970))",
                type: .probabilityMove,
                title: "Probability moved \(movement.change >= 0 ? "up" : "down") \(magnitude.pointsText)",
                market: market,
                matchedMarket: nil,
                severity: movementSeverity(for: magnitude),
                confidence: movementConfidence(for: market.quote.sourceQuality),
                metricLabel: movement.window.displayName + " Move",
                metricValue: movement.change.signedPointsText,
                explanation: "Oddsight compared locally stored observations for this market. The move reflects implied probability, not a guaranteed forecast.",
                detectedDescription: "Live · \(movement.window.displayName)"
            )
        }
    }

    private nonisolated static func signals(for match: MatchedMarket) -> [OddsightSignal] {
        var signals: [OddsightSignal] = []

        if match.confidence >= 0.50 {
            signals.append(
                OddsightSignal(
                    id: "signal-new-match-\(match.id)",
                    type: .newMatchedMarket,
                    title: "\(match.status): \(match.primaryMarket.title)",
                    market: match.primaryMarket,
                    matchedMarket: match,
                    severity: match.confidence >= 0.78 ? .high : .medium,
                    confidence: match.confidence,
                    metricLabel: "Match",
                    metricValue: match.confidence.percentText,
                    explanation: "Oddsight found a live Kalshi-to-Polymarket match candidate. Review the match assessment before comparing prices or treating the contracts as equivalent.",
                    detectedDescription: "Live"
                )
            )
        }

        if let discrepancy = match.discrepancy, discrepancy.absoluteDifference >= 0.05 {
            let difference = discrepancy.absoluteDifference.pointsText
            signals.append(
                OddsightSignal(
                    id: "signal-discrepancy-\(match.id)",
                    type: .crossMarketDiscrepancy,
                    title: "Matched markets differ by \(difference)",
                    market: match.primaryMarket,
                    matchedMarket: match,
                    severity: discrepancySeverity(for: discrepancy.absoluteDifference),
                    confidence: min(match.confidence, discrepancy.sourceQuality.supportsExecutableClaim ? 0.86 : 0.62),
                    metricLabel: "Difference",
                    metricValue: difference,
                    explanation: "Oddsight found similar Kalshi and Polymarket markets with different comparable probabilities. Review the match assessment before treating this as economically equivalent.",
                    detectedDescription: "Live"
                )
            )
        }

        if let arbitrage = match.potentialArbitrage,
           arbitrage.isTheoreticallyPositive,
           arbitrage.grossReturn >= 0.02,
           match.confidence >= 0.50 {
            signals.append(
                OddsightSignal(
                    id: "signal-arbitrage-\(match.id)",
                    type: .potentialArbitrage,
                    title: "Theoretical cross-market gap",
                    market: match.primaryMarket,
                    matchedMarket: match,
                    severity: arbitrage.grossReturn >= 0.08 ? .critical : .high,
                    confidence: min(match.confidence, 0.72),
                    metricLabel: "Gross Return",
                    metricValue: arbitrage.grossReturn.percentText,
                    explanation: "YES and NO asks combine below $1. This excludes fees, slippage, available size, and settlement verification, so it is not guaranteed profit.",
                    detectedDescription: "Live"
                )
            )
        }

        return signals
    }

    private nonisolated static func discrepancySeverity(for difference: Double) -> SignalSeverity {
        if difference >= 0.15 { return .critical }
        if difference >= 0.10 { return .high }
        if difference >= 0.05 { return .medium }
        return .low
    }

    private nonisolated static func movementSeverity(for magnitude: Double) -> SignalSeverity {
        if magnitude >= 0.15 { return .critical }
        if magnitude >= 0.10 { return .high }
        return .medium
    }

    private nonisolated static func movementConfidence(for quality: PriceSourceQuality) -> Double {
        switch quality {
        case .executableBidAsk: 0.90
        case .midpoint: 0.78
        case .lastTrade: 0.62
        case .unavailable: 0.45
        }
    }

    private nonisolated static func severityRank(_ severity: SignalSeverity) -> Int {
        switch severity {
        case .low:
            return 0
        case .medium:
            return 1
        case .high:
            return 2
        case .critical:
            return 3
        }
    }
}
