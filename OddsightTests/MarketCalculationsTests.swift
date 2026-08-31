import Testing
@testable import Oddsight

struct MarketCalculationsTests {
    @Test func kalshiQuoteDerivesExecutableAsks() throws {
        let quote = try MarketCalculations.kalshiQuote(yesBid: 0.42, noBid: 0.55)

        #expect(abs((quote.yesAsk ?? 0) - 0.45) < 0.000_001)
        #expect(abs((quote.noAsk ?? 0) - 0.58) < 0.000_001)
        #expect(quote.sourceQuality == .executableBidAsk)
    }

    @Test func discrepancyUsesWeakestPriceQuality() throws {
        let executable = try MarketCalculations.directQuote(
            yesBid: 0.40,
            yesAsk: 0.44,
            noBid: 0.56,
            noAsk: 0.60
        )
        let lastTrade = try MarketCalculations.directQuote(
            yesBid: nil,
            yesAsk: nil,
            noBid: nil,
            noAsk: nil,
            lastTradePrice: 0.50
        )

        let result = try MarketCalculations.discrepancy(between: executable, and: lastTrade)

        #expect(abs(result.absoluteDifference - 0.08) < 0.000_001)
        #expect(result.sourceQuality == .lastTrade)
    }

    @Test func arbitrageRequiresPositiveExecutableSpread() throws {
        let result = try MarketCalculations.potentialArbitrage(yesAsk: 0.46, noAsk: 0.49)

        #expect(result.isTheoreticallyPositive)
        #expect(abs(result.grossProfit - 0.05) < 0.000_001)
        #expect(abs(result.grossReturn - (0.05 / 0.95)) < 0.000_001)
    }

    @Test func rejectsOutOfRangePrices() {
        #expect(throws: MarketCalculationError.invalidPrice(1.01)) {
            try MarketCalculations.validateProbabilityPrice(1.01)
        }
    }
}
