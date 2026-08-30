import SwiftUI

struct DiscoverView: View {
    @Environment(OddsightMarketStore.self) private var marketStore

    private var biggestMoves: [Market] {
        marketStore.markets
            .sorted { abs($0.probabilityChange24h) > abs($1.probabilityChange24h) }
    }

    var body: some View {
        NavigationStack {
            List {
                DataStatusView(
                    isLoading: marketStore.isLoading,
                    isUsingSampleFallback: marketStore.isUsingSampleFallback,
                    lastUpdatedAt: marketStore.lastUpdatedAt,
                    errorMessage: marketStore.errorMessage,
                    refreshAction: marketStore.refreshMarkets
                )

                if marketStore.isUsingSampleFallback {
                    Section("Top Signals") {
                        ForEach(marketStore.signals.prefix(2)) { signal in
                            NavigationLink {
                                MarketDetailView(market: signal.market, matchedMarket: signal.matchedMarket)
                            } label: {
                                SignalRow(signal: signal)
                            }
                        }
                    }
                }

                Section("Biggest Moves") {
                    ForEach(biggestMoves.prefix(6)) { market in
                        NavigationLink {
                            MarketDetailView(market: market, matchedMarket: marketStore.matchedMarket(for: market))
                        } label: {
                            MarketRow(market: market)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .refreshable {
                await marketStore.refreshMarkets()
            }
        }
    }
}

#Preview {
    DiscoverView()
        .environment(OddsightMarketStore())
}
