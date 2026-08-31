import Foundation
import Observation

@Observable
@MainActor
final class OddsightMarketStore {
    enum DataSourceState: Equatable {
        case initial
        case loading
        case live
        case partial(failedProviders: [PredictionPlatform])
        case sampleFallback(failedProviders: [PredictionPlatform])
    }

    private struct ProviderLoadResult: Sendable {
        let platform: PredictionPlatform
        let markets: [Market]
        let errorDescription: String?
    }

    private let kalshiClient: any PredictionMarketProvider
    private let polymarketClient: any PredictionMarketProvider
    private let snapshotRepository: any MarketSnapshotRepository
    private let alertRepository: any MarketAlertRepository
    private let notificationService: any AlertNotificationDelivering
    private let entitlementConfiguration: EntitlementConfiguration

    var markets: [Market] = SampleOddsightData.markets
    var dataSourceState: DataSourceState = .initial
    var errorMessage: String?
    var lastUpdatedAt: Date?
    private(set) var snapshotHistory: [String: [MarketSnapshot]] = [:]
    private(set) var historyErrors: [String: String] = [:]
    private(set) var alerts: [MarketAlert] = []
    private(set) var alertErrorMessage: String?
    private(set) var notificationAuthorization: AlertNotificationAuthorization = .notDetermined
    private(set) var currentTier: SubscriptionTier
    private(set) var entitlementMessage: String?

    private var liveMatches: [MatchedMarket] = []
    private var liveSignals: [OddsightSignal] = []

    init(
        kalshiClient: any PredictionMarketProvider = KalshiMarketClient(),
        polymarketClient: any PredictionMarketProvider = PolymarketMarketClient(),
        snapshotRepository: (any MarketSnapshotRepository)? = nil,
        alertRepository: (any MarketAlertRepository)? = nil,
        notificationService: (any AlertNotificationDelivering)? = nil,
        currentTier: SubscriptionTier = .free,
        entitlementConfiguration: EntitlementConfiguration = .defaultPlans
    ) {
        self.kalshiClient = kalshiClient
        self.polymarketClient = polymarketClient
        self.snapshotRepository = snapshotRepository ?? LocalMarketSnapshotRepository()
        self.alertRepository = alertRepository ?? LocalMarketAlertRepository()
        self.notificationService = notificationService ?? LocalAlertNotificationService()
        self.currentTier = currentTier
        self.entitlementConfiguration = entitlementConfiguration
    }

    var matches: [MatchedMarket] {
        isUsingSampleFallback ? SampleOddsightData.matches : liveMatches
    }

    var isLoading: Bool {
        dataSourceState == .loading
    }

    var isUsingSampleFallback: Bool {
        if case .sampleFallback = dataSourceState { return true }
        return dataSourceState == .initial
    }

    var signals: [OddsightSignal] {
        let availableSignals = allAvailableSignals
        guard let limit = entitlements.scannerSignalLimit else { return availableSignals }
        return Array(availableSignals.prefix(limit))
    }

    var isScannerLimited: Bool {
        guard let limit = entitlements.scannerSignalLimit else { return false }
        return allAvailableSignals.count > limit
    }

    var entitlements: PlanEntitlements {
        entitlementConfiguration.entitlements(for: currentTier)
    }

    var canCreateAlert: Bool {
        entitlements.canCreateAlert(existingCount: alerts.count)
    }

    var alertUsageDescription: String {
        guard let limit = entitlements.alertLimit else { return "\(alerts.count) saved · Unlimited" }
        return "\(alerts.count) of \(limit) saved"
    }

    private var allAvailableSignals: [OddsightSignal] {
        isUsingSampleFallback ? SampleOddsightData.signals : liveSignals
    }

    func refreshMarkets() async {
        dataSourceState = .loading
        errorMessage = nil

        async let kalshiResult = Self.loadMarkets(from: kalshiClient, platform: .kalshi, limit: 250)
        async let polymarketResult = Self.loadMarkets(from: polymarketClient, platform: .polymarket, limit: 100)
        let results = await [kalshiResult, polymarketResult]
        let liveMarkets = results.flatMap(\.markets)
        let failedProviders = results.compactMap { result in
            result.errorDescription == nil ? nil : result.platform
        }
        var providerErrors = results.compactMap { result in
            result.errorDescription.map { "\(result.platform.rawValue): \($0)" }
        }

        if liveMarkets.isEmpty {
            errorMessage = providerErrors.isEmpty ? "Providers returned no active binary markets. Showing sample data." : providerErrors.joined(separator: " ")
            dataSourceState = .sampleFallback(failedProviders: failedProviders)
        } else {
            var sortedMarkets = liveMarkets.sorted { $0.volume24h > $1.volume24h }
            var movements: [MarketMovement] = []
            do {
                movements = try await snapshotRepository.record(markets: sortedMarkets, at: Date())
                let changes24h = Dictionary(
                    movements.filter { $0.window == .twentyFourHours }.map { ($0.marketID, $0.change) },
                    uniquingKeysWith: { _, latest in latest }
                )
                sortedMarkets = sortedMarkets.map { market in
                    changes24h[market.id].map(market.withProbabilityChange24h) ?? market
                }
            } catch {
                providerErrors.append("History: \(error.localizedDescription)")
            }
            let matches = MarketMatcher.matchMarkets(sortedMarkets)
            markets = sortedMarkets
            liveMatches = matches
            liveSignals = SignalBuilder.buildSignals(for: matches, movements: movements, markets: sortedMarkets)
            lastUpdatedAt = Date()
            dataSourceState = failedProviders.isEmpty ? .live : .partial(failedProviders: failedProviders)
            errorMessage = providerErrors.isEmpty ? nil : providerErrors.joined(separator: " ")
            await evaluateAlerts(using: sortedMarkets)
        }
    }

    func matchedMarket(for market: Market) -> MatchedMarket? {
        matches.first { match in
            match.primaryMarket.id == market.id || match.comparisonMarket.id == market.id
        }
    }

    func loadHistory(for marketID: String) async {
        do {
            snapshotHistory[marketID] = try await snapshotRepository.snapshots(for: marketID)
            historyErrors[marketID] = nil
        } catch {
            historyErrors[marketID] = error.localizedDescription
        }
    }

    func loadAlerts() async {
        do {
            alerts = try await alertRepository.load().sorted { $0.createdAt > $1.createdAt }
            alertErrorMessage = nil
        } catch {
            alertErrorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func addAlert(for market: Market, direction: ProbabilityAlertDirection, threshold: Double) async -> Bool {
        guard (0...1).contains(threshold) else { return false }
        guard canCreateAlert else {
            entitlementMessage = "Your \(currentTier.displayName) plan has reached its saved-alert limit."
            return false
        }
        alerts.insert(
            MarketAlert(
                id: UUID(),
                marketID: market.id,
                marketTitle: market.title,
                platform: market.platform,
                direction: direction,
                threshold: threshold,
                isEnabled: true,
                createdAt: Date(),
                triggeredAt: nil,
                latestProbability: market.probability,
                notificationDeliveredAt: nil
            ),
            at: 0
        )
        await persistAlerts()
        entitlementMessage = nil
        return true
    }

    func setAlertEnabled(_ alertID: UUID, isEnabled: Bool) async {
        guard let index = alerts.firstIndex(where: { $0.id == alertID }) else { return }
        alerts[index].isEnabled = isEnabled
        await persistAlerts()
    }

    func deleteAlerts(at offsets: IndexSet) async {
        for index in offsets.sorted(by: >) {
            alerts.remove(at: index)
        }
        await persistAlerts()
    }

    func refreshNotificationAuthorization() async {
        notificationAuthorization = await notificationService.authorizationStatus()
    }

    func requestNotificationAuthorization() async {
        do {
            _ = try await notificationService.requestAuthorization()
            await refreshNotificationAuthorization()
            await deliverPendingNotifications()
        } catch {
            alertErrorMessage = error.localizedDescription
        }
    }

    private func evaluateAlerts(using markets: [Market]) async {
        let updated = MarketAlertEvaluator.evaluate(alerts, markets: markets, at: Date())
        guard updated != alerts else { return }
        alerts = updated
        await persistAlerts()
        await deliverPendingNotifications()
    }

    private func deliverPendingNotifications() async {
        guard await notificationService.authorizationStatus() == .authorized else { return }
        var didChange = false
        for index in alerts.indices where alerts[index].triggeredAt != nil && alerts[index].notificationDeliveredAt == nil {
            do {
                try await notificationService.deliver(alert: alerts[index])
                alerts[index].notificationDeliveredAt = Date()
                didChange = true
            } catch {
                alertErrorMessage = error.localizedDescription
            }
        }
        if didChange { await persistAlerts() }
    }

    private func persistAlerts() async {
        do {
            try await alertRepository.save(alerts)
            alertErrorMessage = nil
        } catch {
            alertErrorMessage = error.localizedDescription
        }
    }

    private nonisolated static func loadMarkets(
        from provider: any PredictionMarketProvider,
        platform: PredictionPlatform,
        limit: Int
    ) async -> ProviderLoadResult {
        do {
            return ProviderLoadResult(
                platform: platform,
                markets: try await provider.fetchActiveMarkets(limit: limit),
                errorDescription: nil
            )
        } catch {
            return ProviderLoadResult(
                platform: platform,
                markets: [],
                errorDescription: error.localizedDescription
            )
        }
    }
}
