import Foundation

struct AppDiagnostics: Equatable, Sendable {
    let dataStatus: String
    let marketCount: Int
    let matchCount: Int
    let signalCount: Int
    let savedAlertCount: Int
    let lastUpdatedAt: Date?
    let providerError: String?

    @MainActor
    init(store: OddsightMarketStore) {
        dataStatus = Self.displayName(for: store.dataSourceState)
        marketCount = store.markets.count
        matchCount = store.matches.count
        signalCount = store.signals.count
        savedAlertCount = store.alerts.count
        lastUpdatedAt = store.lastUpdatedAt
        providerError = store.errorMessage
    }

    nonisolated static func displayName(for state: OddsightMarketStore.DataSourceState) -> String {
        switch state {
        case .initial: "Sample data"
        case .loading: "Refreshing"
        case .live: "Live"
        case .partial(let providers):
            "Partial · \(providers.map(\.rawValue).joined(separator: ", ")) unavailable"
        case .sampleFallback:
            "Sample fallback"
        }
    }
}

enum AppMetadata {
    static var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
}
