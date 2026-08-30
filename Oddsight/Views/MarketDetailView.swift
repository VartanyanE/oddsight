import SwiftUI

struct MarketDetailView: View {
    let market: Market
    let matchedMarket: MatchedMarket?

    private var quote: BinaryMarketQuote {
        market.quote
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        PlatformBadge(platform: market.platform)
                        Text(market.category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    Text(market.title)
                        .font(.title2.weight(.bold))

                    Text(market.normalizedQuestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Market Data") {
                LabeledContent("Implied probability", value: market.probability.percentText)
                LabeledContent("YES bid", value: quote.yesBid?.percentText ?? "Unavailable")
                LabeledContent("YES ask", value: quote.yesAsk?.percentText ?? "Unavailable")
                LabeledContent("NO bid", value: quote.noBid?.percentText ?? "Unavailable")
                LabeledContent("NO ask", value: quote.noAsk?.percentText ?? "Unavailable")
                LabeledContent("Price quality", value: quote.sourceQuality.displayName)
                LabeledContent("24h volume", value: market.volume24h.compactDollarText)
                LabeledContent("Liquidity", value: market.liquidity.compactDollarText)
                LabeledContent("24h move", value: market.probabilityChange24h.signedPointsText)
                LabeledContent("Expiration", value: market.expirationDescription)
            }

            if let matchedMarket {
                Section("Matched Market") {
                    let otherMarket = matchedMarket.primaryMarket.id == market.id ? matchedMarket.comparisonMarket : matchedMarket.primaryMarket
                    let discrepancy = matchedMarket.discrepancy

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(matchedMarket.status)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("Confidence \(matchedMarket.confidence.percentText)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Divider()

                        MarketComparisonLine(title: market.platform.rawValue, probability: market.probability)
                        MarketComparisonLine(title: otherMarket.platform.rawValue, probability: otherMarket.probability)
                        MarketComparisonLine(title: "Difference", probability: matchedMarket.probabilityDifference)
                        LabeledContent("Comparison quality", value: discrepancy?.sourceQuality.displayName ?? "Unavailable")
                    }
                    .padding(.vertical, 4)
                }

                if let arbitrage = matchedMarket.potentialArbitrage {
                    Section("Potential Arbitrage") {
                        LabeledContent("YES ask", value: arbitrage.yesAsk.percentText)
                        LabeledContent("NO ask", value: arbitrage.noAsk.percentText)
                        LabeledContent("Combined cost", value: arbitrage.combinedCost.currencyText)
                        LabeledContent("Gross profit", value: arbitrage.grossProfit.currencyText)
                        LabeledContent("Gross return", value: arbitrage.grossReturn.percentText)
                        Text("Theoretical only. Fees, slippage, available size, and settlement equivalence are not verified in sample data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Resolution") {
                Text(market.resolutionSummary)
                    .foregroundStyle(.secondary)
            }

            Section("Source") {
                if let url = URL(string: market.sourceURL) {
                    Link(destination: url) {
                        Label("Open on \(market.platform.rawValue)", systemImage: "arrow.up.forward.app")
                    }
                } else {
                    Text("Source URL unavailable")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Market")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MarketComparisonLine: View {
    let title: String
    let probability: Double

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(probability.percentText)
                .font(.body.weight(.semibold))
        }
    }
}

private extension PriceSourceQuality {
    var displayName: String {
        switch self {
        case .executableBidAsk:
            return "Executable bid/ask"
        case .midpoint:
            return "Midpoint"
        case .lastTrade:
            return "Last trade"
        case .unavailable:
            return "Unavailable"
        }
    }
}

private extension Double {
    var currencyText: String {
        formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

#Preview {
    NavigationStack {
        MarketDetailView(market: SampleOddsightData.kalshiFed, matchedMarket: SampleOddsightData.fedMatch)
    }
}
