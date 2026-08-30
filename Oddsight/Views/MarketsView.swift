import SwiftUI

struct MarketsView: View {
    @State private var searchText = ""
    @State private var selectedCategory: MarketCategory?
    private let markets = SampleOddsightData.markets

    private var filteredMarkets: [Market] {
        markets.filter { market in
            let matchesSearch = searchText.isEmpty || market.title.localizedCaseInsensitiveContains(searchText) || market.normalizedQuestion.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || market.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(nil as MarketCategory?)
                        ForEach(MarketCategory.allCases) { category in
                            Text(category.rawValue).tag(category as MarketCategory?)
                        }
                    }
                }

                Section("Markets") {
                    ForEach(filteredMarkets) { market in
                        NavigationLink {
                            MarketDetailView(market: market, matchedMarket: SampleOddsightData.matches.first { $0.primaryMarket.id == market.id || $0.comparisonMarket.id == market.id })
                        } label: {
                            MarketRow(market: market)
                        }
                    }
                }
            }
            .navigationTitle("Market")
            .searchable(text: $searchText, prompt: "Search markets")
        }
    }
}

#Preview {
    MarketsView()
}
