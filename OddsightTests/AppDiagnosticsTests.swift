import Testing
@testable import Oddsight

@MainActor
struct AppDiagnosticsTests {
    @Test func capturesCurrentStoreState() {
        let store = OddsightMarketStore()

        let diagnostics = AppDiagnostics(store: store)

        #expect(diagnostics.dataStatus == "Sample data")
        #expect(diagnostics.marketCount == store.markets.count)
        #expect(diagnostics.matchCount == store.matches.count)
        #expect(diagnostics.signalCount == store.signals.count)
        #expect(diagnostics.savedAlertCount == 0)
        #expect(diagnostics.lastUpdatedAt == nil)
    }

    @Test func describesPartialProviderState() {
        let description = AppDiagnostics.displayName(
            for: .partial(failedProviders: [.polymarket])
        )

        #expect(description == "Partial · Polymarket unavailable")
    }
}
