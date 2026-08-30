import Foundation

struct MarketMatchCandidate: Equatable {
    let primaryMarket: Market
    let comparisonMarket: Market
    let confidence: Double
    let status: String
    let eventSimilarity: Double
    let categoryCompatible: Bool
    let expirationSimilarity: Double
    let sharedTerms: [String]
    let reasons: [String]
    let risks: [String]
}

enum MarketMatcher {
    nonisolated private static let ignoredTerms: Set<String> = [
        "the", "and", "for", "with", "will", "this", "that", "from", "into", "over", "under",
        "market", "resolve", "yes", "no", "before", "after", "above", "below", "than", "what",
        "when", "where", "which", "have", "has", "had", "does", "did", "its", "his", "her"
    ]

    nonisolated static func matchMarkets(_ markets: [Market]) -> [MatchedMarket] {
        candidateMatches(from: markets).map { candidate in
            MatchedMarket(
                id: "live-match-\(candidate.primaryMarket.id)-\(candidate.comparisonMarket.id)",
                primaryMarket: candidate.primaryMarket,
                comparisonMarket: candidate.comparisonMarket,
                confidence: candidate.confidence,
                status: candidate.status,
                assessment: MatchAssessment(
                    eventSimilarity: candidate.eventSimilarity,
                    categoryCompatible: candidate.categoryCompatible,
                    expirationSimilarity: candidate.expirationSimilarity,
                    sharedTerms: candidate.sharedTerms,
                    reasons: candidate.reasons,
                    risks: candidate.risks,
                    generatedBy: "Deterministic V1"
                )
            )
        }
    }

    nonisolated static func candidateMatches(from markets: [Market]) -> [MarketMatchCandidate] {
        let kalshiMarkets = markets.filter { $0.platform == .kalshi }
        let polymarketMarkets = markets.filter { $0.platform == .polymarket }
        var candidates: [MarketMatchCandidate] = []

        for kalshiMarket in kalshiMarkets {
            let kalshiTerms = normalizedTerms(for: kalshiMarket)

            for polymarketMarket in polymarketMarkets {
                let categoryCompatible = categoriesAreCompatible(kalshiMarket.category, polymarketMarket.category)
                guard categoryCompatible else {
                    continue
                }

                let polymarketTerms = normalizedTerms(for: polymarketMarket)
                let sharedTerms = Array(kalshiTerms.intersection(polymarketTerms)).sorted()
                let unionCount = kalshiTerms.union(polymarketTerms).count
                guard unionCount > 0 else { continue }

                let termSimilarity = Double(sharedTerms.count) / Double(unionCount)
                let titleContainment = containmentScore(kalshiTerms, polymarketTerms)
                let expirationScore = expirationCompatibility(kalshiMarket.expirationDescription, polymarketMarket.expirationDescription)
                let confidence = min(0.92, (termSimilarity * 0.55) + (titleContainment * 0.30) + (expirationScore * 0.15))

                guard confidence >= 0.34, sharedTerms.count >= 2 else {
                    continue
                }

                candidates.append(
                    MarketMatchCandidate(
                        primaryMarket: kalshiMarket,
                        comparisonMarket: polymarketMarket,
                        confidence: confidence,
                        status: status(for: confidence),
                        eventSimilarity: max(termSimilarity, titleContainment),
                        categoryCompatible: categoryCompatible,
                        expirationSimilarity: expirationScore,
                        sharedTerms: sharedTerms,
                        reasons: reasons(
                            sharedTerms: sharedTerms,
                            categoryCompatible: categoryCompatible,
                            expirationScore: expirationScore
                        ),
                        risks: risks(
                            confidence: confidence,
                            expirationScore: expirationScore,
                            primaryMarket: kalshiMarket,
                            comparisonMarket: polymarketMarket
                        )
                    )
                )
            }
        }

        return candidates
            .sorted { first, second in
                if first.confidence == second.confidence {
                    return first.primaryMarket.volume24h + first.comparisonMarket.volume24h > second.primaryMarket.volume24h + second.comparisonMarket.volume24h
                }
                return first.confidence > second.confidence
            }
            .prefix(25)
            .map { $0 }
    }

    nonisolated static func normalizedTerms(for market: Market) -> Set<String> {
        let text = "\(market.title) \(market.normalizedQuestion)"
            .lowercased()
            .replacingOccurrences(of: "$", with: " usd ")
            .replacingOccurrences(of: "%", with: " percent ")

        let rawTerms = text.split { character in
            !character.isLetter && !character.isNumber
        }

        return Set(rawTerms.compactMap { rawTerm in
            let term = alias(String(rawTerm))
            guard term.count >= 3, !ignoredTerms.contains(term) else {
                return nil
            }
            return term
        })
    }

    private nonisolated static func alias(_ term: String) -> String {
        switch term {
        case "btc":
            return "bitcoin"
        case "eth":
            return "ethereum"
        case "usa", "u", "us":
            return "unitedstates"
        case "fed", "fomc":
            return "federalreserve"
        case "trump", "donaldtrump":
            return "trump"
        default:
            return term
        }
    }

    private nonisolated static func categoriesAreCompatible(_ first: MarketCategory, _ second: MarketCategory) -> Bool {
        first == second || first == .other || second == .other
    }

    private nonisolated static func containmentScore(_ first: Set<String>, _ second: Set<String>) -> Double {
        guard !first.isEmpty, !second.isEmpty else { return 0 }
        let sharedCount = first.intersection(second).count
        return Double(sharedCount) / Double(min(first.count, second.count))
    }

    private nonisolated static func expirationCompatibility(_ first: String, _ second: String) -> Double {
        let firstTerms = Set(first.lowercased().split { !$0.isLetter && !$0.isNumber })
        let secondTerms = Set(second.lowercased().split { !$0.isLetter && !$0.isNumber })
        guard !firstTerms.isEmpty, !secondTerms.isEmpty else { return 0.25 }
        return firstTerms.intersection(secondTerms).isEmpty ? 0.15 : 1.0
    }

    private nonisolated static func status(for confidence: Double) -> String {
        if confidence >= 0.78 { return "High Confidence" }
        if confidence >= 0.50 { return "Possible Match" }
        return "Needs Review"
    }

    private nonisolated static func reasons(sharedTerms: [String], categoryCompatible: Bool, expirationScore: Double) -> [String] {
        var reasons: [String] = []
        if categoryCompatible {
            reasons.append("Markets are in compatible categories.")
        }
        if !sharedTerms.isEmpty {
            reasons.append("Shared normalized terms: \(sharedTerms.prefix(8).joined(separator: ", ")).")
        }
        if expirationScore >= 0.75 {
            reasons.append("Expiration text has overlapping terms.")
        }
        return reasons
    }

    private nonisolated static func risks(
        confidence: Double,
        expirationScore: Double,
        primaryMarket: Market,
        comparisonMarket: Market
    ) -> [String] {
        var risks = [
            "Settlement rules, resolution source, timezone, and edge cases are not verified by V1 matching."
        ]

        if confidence < 0.78 {
            risks.append("Confidence is below the high-confidence threshold.")
        }
        if expirationScore < 0.75 {
            risks.append("Expiration text does not strongly overlap.")
        }
        if primaryMarket.resolutionSummary.contains("unavailable") || comparisonMarket.resolutionSummary.contains("unavailable") {
            risks.append("At least one market has incomplete resolution rules in the current response.")
        }

        return risks
    }
}
