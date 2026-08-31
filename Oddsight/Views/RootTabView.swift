import SwiftUI

struct RootTabView: View {
    @State private var marketStore = OddsightMarketStore()
    @State private var router = AppRouter()
    let automaticallyRefreshes: Bool

    init(automaticallyRefreshes: Bool = true) {
        self.automaticallyRefreshes = automaticallyRefreshes
    }

    var body: some View {
        TabView(selection: Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )) {
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "safari")
                }
                .tag(AppTab.discover)

            ScannerView()
                .tabItem {
                    Label("Scanner", systemImage: "scope")
                }
                .tag(AppTab.scanner)

            MarketsView()
                .tabItem {
                    Label("Market", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(AppTab.markets)

            AlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell")
                }
                .tag(AppTab.alerts)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.cyan)
        .environment(marketStore)
        .environment(router)
        .onReceive(NotificationCenter.default.publisher(for: .oddsightDidOpenAlert)) { notification in
            if let alertID = NotificationRoute.alertID(from: notification.userInfo ?? [:]) {
                router.openAlert(alertID)
                _ = OddsightAppDelegate.consumePendingAlertID()
            }
        }
        .task {
            if let pendingAlertID = OddsightAppDelegate.consumePendingAlertID() {
                router.openAlert(pendingAlertID)
            }
            if automaticallyRefreshes {
                await marketStore.loadAlerts()
                await marketStore.refreshMarkets()
            }
        }
    }
}

#Preview {
    RootTabView(automaticallyRefreshes: false)
}
