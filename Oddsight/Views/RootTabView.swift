import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "sparkline")
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
    }
}

#Preview {
    RootTabView()
}
