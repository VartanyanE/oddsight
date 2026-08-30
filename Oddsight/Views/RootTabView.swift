import SwiftUI

struct RootTabView: View {
    @State private var marketStore = OddsightMarketStore()

    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }

            ScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "scope")
                }

            MarketsView()
                .tabItem {
                    Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                }

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
        }
        .tint(.cyan)
        .environment(marketStore)
        .task {
            await marketStore.refreshMarkets()
        }
    }
}

#Preview {
    RootTabView()
}
