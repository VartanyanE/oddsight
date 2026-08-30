import Foundation

enum PriceSourceQuality: String, Equatable {
    case executableBidAsk
    case midpoint
    case lastTrade
    case unavailable

    nonisolated var supportsExecutableClaim: Bool {
        self == .executableBidAsk
    }
}

struct BinaryMarketQuote: Equatable {
    let yesBid: Double?
    let yesAsk: Double?
    let noBid: Double?
    let noAsk: Double?
    let lastTradePrice: Double?
    let midpoint: Double?
    let sourceQuality: PriceSourceQuality

    nonisolated var comparableProbability: Double? {
        switch sourceQuality {
        case .executableBidAsk:
            if let yesBid, let yesAsk {
                return (yesBid + yesAsk) / 2
            }
            return midpoint ?? lastTradePrice
        case .midpoint:
            return midpoint
        case .lastTrade:
            return lastTradePrice
        case .unavailable:
            return nil
        }
    }
}

struct CrossMarketDiscrepancy: Equatable {
    let probabilityA: Double
    let probabilityB: Double
    let absoluteDifference: Double
    let sourceQuality: PriceSourceQuality
}

struct PotentialArbitrage: Equatable {
    let yesAsk: Double
    let noAsk: Double
    let combinedCost: Double
    let grossProfit: Double
    let grossReturn: Double
    let isTheoreticallyPositive: Bool
    let sourceQuality: PriceSourceQuality
}

enum MarketCalculationError: Error, Equatable {
    case invalidPrice(Double)
    case missingComparableProbability
    case missingExecutableAsk
    case nonPositiveCost
}

enum MarketCalculations {
    nonisolated static func validateProbabilityPrice(_ price: Double) throws -> Double {
        guard (0...1).contains(price) else {
            throw MarketCalculationError.invalidPrice(price)
        }
        return price
    }

    nonisolated static func askFromOppositeSideBid(_ oppositeSideBid: Double) throws -> Double {
        let price = try validateProbabilityPrice(oppositeSideBid)
        return 1 - price
    }

    nonisolated static func kalshiQuote(
        yesBid: Double?,
        noBid: Double?,
        lastTradePrice: Double? = nil,
        midpoint: Double? = nil
    ) throws -> BinaryMarketQuote {
        let validatedYesBid = try yesBid.map(validateProbabilityPrice)
        let validatedNoBid = try noBid.map(validateProbabilityPrice)
        let validatedLastTrade = try lastTradePrice.map(validateProbabilityPrice)
        let validatedMidpoint = try midpoint.map(validateProbabilityPrice)

        let yesAsk = try validatedNoBid.map(askFromOppositeSideBid)
        let noAsk = try validatedYesBid.map(askFromOppositeSideBid)
        let quality: PriceSourceQuality = validatedYesBid != nil && yesAsk != nil ? .executableBidAsk : validatedMidpoint != nil ? .midpoint : validatedLastTrade != nil ? .lastTrade : .unavailable

        return BinaryMarketQuote(
            yesBid: validatedYesBid,
            yesAsk: yesAsk,
            noBid: validatedNoBid,
            noAsk: noAsk,
            lastTradePrice: validatedLastTrade,
            midpoint: validatedMidpoint,
            sourceQuality: quality
        )
    }

    nonisolated static func directQuote(
        yesBid: Double?,
        yesAsk: Double?,
        noBid: Double?,
        noAsk: Double?,
        lastTradePrice: Double? = nil,
        midpoint: Double? = nil
    ) throws -> BinaryMarketQuote {
        let validatedYesBid = try yesBid.map(validateProbabilityPrice)
        let validatedYesAsk = try yesAsk.map(validateProbabilityPrice)
        let validatedNoBid = try noBid.map(validateProbabilityPrice)
        let validatedNoAsk = try noAsk.map(validateProbabilityPrice)
        let validatedLastTrade = try lastTradePrice.map(validateProbabilityPrice)
        let validatedMidpoint = try midpoint.map(validateProbabilityPrice)
        let quality: PriceSourceQuality = validatedYesBid != nil && validatedYesAsk != nil ? .executableBidAsk : validatedMidpoint != nil ? .midpoint : validatedLastTrade != nil ? .lastTrade : .unavailable

        return BinaryMarketQuote(
            yesBid: validatedYesBid,
            yesAsk: validatedYesAsk,
            noBid: validatedNoBid,
            noAsk: validatedNoAsk,
            lastTradePrice: validatedLastTrade,
            midpoint: validatedMidpoint,
            sourceQuality: quality
        )
    }

    nonisolated static func discrepancy(between firstQuote: BinaryMarketQuote, and secondQuote: BinaryMarketQuote) throws -> CrossMarketDiscrepancy {
        guard let firstProbability = firstQuote.comparableProbability,
              let secondProbability = secondQuote.comparableProbability else {
            throw MarketCalculationError.missingComparableProbability
        }

        return CrossMarketDiscrepancy(
            probabilityA: firstProbability,
            probabilityB: secondProbability,
            absoluteDifference: abs(firstProbability - secondProbability),
            sourceQuality: combinedQuality(firstQuote.sourceQuality, secondQuote.sourceQuality)
        )
    }

    nonisolated static func potentialArbitrage(yesAsk: Double?, noAsk: Double?) throws -> PotentialArbitrage {
        guard let yesAsk, let noAsk else {
            throw MarketCalculationError.missingExecutableAsk
        }

        let validatedYesAsk = try validateProbabilityPrice(yesAsk)
        let validatedNoAsk = try validateProbabilityPrice(noAsk)
        let combinedCost = validatedYesAsk + validatedNoAsk

        guard combinedCost > 0 else {
            throw MarketCalculationError.nonPositiveCost
        }

        let grossProfit = 1 - combinedCost

        return PotentialArbitrage(
            yesAsk: validatedYesAsk,
            noAsk: validatedNoAsk,
            combinedCost: combinedCost,
            grossProfit: grossProfit,
            grossReturn: grossProfit / combinedCost,
            isTheoreticallyPositive: combinedCost < 1,
            sourceQuality: .executableBidAsk
        )
    }

    nonisolated private static func combinedQuality(_ first: PriceSourceQuality, _ second: PriceSourceQuality) -> PriceSourceQuality {
        if first == .unavailable || second == .unavailable {
            return .unavailable
        }
        if first == .lastTrade || second == .lastTrade {
            return .lastTrade
        }
        if first == .midpoint || second == .midpoint {
            return .midpoint
        }
        return .executableBidAsk
    }
}
