import SwiftUI

struct MarketDetailView: View {
    let market: Market
    let matchedMarket: MatchedMarket?

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
                LabeledContent("Best bid", value: market.bestBid?.percentText ?? "Unavailable")
                LabeledContent("Best ask", value: market.bestAsk?.percentText ?? "Unavailable")
                LabeledContent("24h volume", value: market.volume24h.compactDollarText)
                LabeledContent("Liquidity", value: market.liquidity.compactDollarText)
                LabeledContent("24h move", value: market.probabilityChange24h.signedPointsText)
                LabeledContent("Expiration", value: market.expirationDescription)
            }

            if let matchedMarket {
                Section("Matched Market") {
                    let otherMarket = matchedMarket.primaryMarket.id == market.id ? matchedMarket.comparisonMarket : matchedMarket.primaryMarket

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
                    }
                    .padding(.vertical, 4)
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

#Preview {
    NavigationStack {
        MarketDetailView(market: SampleOddsightData.kalshiFed, matchedMarket: SampleOddsightData.fedMatch)
    }
}
