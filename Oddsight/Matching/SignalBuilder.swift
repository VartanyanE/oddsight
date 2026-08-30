import Foundation

enum SignalBuilder {
    nonisolated static func buildSignals(for matches: [MatchedMarket]) -> [OddsightSignal] {
        matches.flatMap { match in
            signals(for: match)
        }
        .sorted { first, second in
            severityRank(first.severity) == severityRank(second.severity)
                ? first.confidence > second.confidence
                : severityRank(first.severity) > severityRank(second.severity)
        }
    }

    private nonisolated static func signals(for match: MatchedMarket) -> [OddsightSignal] {
        var signals: [OddsightSignal] = []

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
