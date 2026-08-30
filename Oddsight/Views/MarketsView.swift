import SwiftUI

struct MarketsView: View {
    @Environment(OddsightMarketStore.self) private var marketStore
    @State private var searchText = ""
    @State private var selectedCategory: MarketCategory?

    private var filteredMarkets: [Market] {
        marketStore.markets.filter { market in
            let matchesSearch = searchText.isEmpty || market.title.localizedCaseInsensitiveContains(searchText) || market.normalizedQuestion.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || market.category == selectedCategory
            return matchesSearch && matchesCategory
        }
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

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(nil as MarketCategory?)
                        ForEach(MarketCategory.allCases) { category in
                            Text(category.rawValue).tag(category as MarketCategory?)
                        }
                    }
                }

                Section("Markets") {
                    if filteredMarkets.isEmpty {
                        ContentUnavailableView("No markets", systemImage: "magnifyingglass", description: Text("Try a different search or category."))
                    } else {
                        ForEach(filteredMarkets) { market in
                            NavigationLink {
                                MarketDetailView(market: market, matchedMarket: marketStore.matchedMarket(for: market))
                            } label: {
                                MarketRow(market: market)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Market")
            .searchable(text: $searchText, prompt: "Search markets")
            .refreshable {
                await marketStore.refreshMarkets()
            }
        }
    }
}

#Preview {
    MarketsView()
        .environment(OddsightMarketStore())
}
