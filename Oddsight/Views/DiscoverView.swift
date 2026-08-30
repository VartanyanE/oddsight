import SwiftUI

struct DiscoverView: View {
    private let signals = SampleOddsightData.signals
    private let markets = SampleOddsightData.markets

    var body: some View {
        NavigationStack {
            List {
                Section("Top Signals") {
                    ForEach(signals.prefix(2)) { signal in
                        NavigationLink {
                            MarketDetailView(market: signal.market, matchedMarket: signal.matchedMarket)
                        } label: {
                            SignalRow(signal: signal)
                        }
                    }
                }

                Section("Biggest Moves") {
                    ForEach(markets.sorted { abs($0.probabilityChange24h) > abs($1.probabilityChange24h) }.prefix(3)) { market in
                        NavigationLink {
                            MarketDetailView(market: market, matchedMarket: SampleOddsightData.matches.first { $0.primaryMarket.id == market.id || $0.comparisonMarket.id == market.id })
                        } label: {
                            MarketRow(market: market)
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("Fresh sample data", systemImage: "clock")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}
