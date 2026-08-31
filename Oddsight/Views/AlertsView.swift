import SwiftUI
import UIKit

struct AlertsView: View {
    @Environment(OddsightMarketStore.self) private var marketStore
    @Environment(AppRouter.self) private var router
    @State private var path: [UUID] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Plan") {
                    LabeledContent("Current plan", value: marketStore.currentTier.displayName)
                    LabeledContent("Alert usage", value: marketStore.alertUsageDescription)
                    if !marketStore.canCreateAlert {
                        Label("Alert limit reached. Plan upgrades are coming later.", systemImage: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = marketStore.alertErrorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Notifications") {
                    LabeledContent("Status", value: marketStore.notificationAuthorization.displayName)

                    switch marketStore.notificationAuthorization {
                    case .notDetermined:
                        Button("Enable Notifications") {
                            Task { await marketStore.requestNotificationAuthorization() }
                        }
                    case .denied:
                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        }
                    case .authorized:
                        Label("Triggered alerts can notify you while Oddsight is running.", systemImage: "checkmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Probability Alerts") {
                    if marketStore.alerts.isEmpty {
                        ContentUnavailableView(
                            "No alerts yet",
                            systemImage: "bell",
                            description: Text("Open a market and create a probability threshold alert.")
                        )
                    } else {
                        ForEach(marketStore.alerts) { alert in
                            HStack(spacing: 12) {
                                NavigationLink(value: alert.id) {
                                    MarketAlertRow(alert: alert)
                                }
                                Toggle(
                                    "Enabled",
                                    isOn: Binding(
                                        get: { alert.isEnabled },
                                        set: { enabled in
                                            Task { await marketStore.setAlertEnabled(alert.id, isEnabled: enabled) }
                                        }
                                    )
                                )
                                .labelsHidden()
                            }
                        }
                        .onDelete { offsets in
                            Task { await marketStore.deleteAlerts(at: offsets) }
                        }
                    }
                }

                Section {
                    Text("Alerts are evaluated on this device whenever live markets refresh. Remote push and background server evaluation require the future backend milestone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Alerts")
            .navigationDestination(for: UUID.self) { alertID in
                AlertDetailView(alertID: alertID)
            }
            .task {
                await marketStore.loadAlerts()
                await marketStore.refreshNotificationAuthorization()
                openPendingAlertIfAvailable()
            }
            .onChange(of: router.pendingAlertID) { _, _ in openPendingAlertIfAvailable() }
        }
    }

    private func openPendingAlertIfAvailable() {
        guard let alertID = router.pendingAlertID,
              marketStore.alerts.contains(where: { $0.id == alertID }) else { return }
        path = [alertID]
        _ = router.consumePendingAlert()
    }
}

private struct MarketAlertRow: View {
    let alert: MarketAlert

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: alert.isTriggered ? "bell.badge.fill" : "bell")
                    .foregroundStyle(alert.isTriggered ? .orange : .cyan)
                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.marketTitle)
                        .font(.headline)
                        .lineLimit(2)
                    Text("\(alert.direction.displayName) \(alert.threshold.percentText) · \(alert.platform.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if alert.isTriggered {
                Label("Triggered", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            } else if let latestProbability = alert.latestProbability {
                Text("Latest: \(latestProbability.percentText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AlertDetailView: View {
    @Environment(OddsightMarketStore.self) private var marketStore
    let alertID: UUID

    private var alert: MarketAlert? {
        marketStore.alerts.first { $0.id == alertID }
    }

    private var market: Market? {
        guard let alert else { return nil }
        return marketStore.markets.first { $0.id == alert.marketID }
    }

    var body: some View {
        List {
            if let alert {
                Section("Condition") {
                    LabeledContent("Market", value: alert.marketTitle)
                    LabeledContent("Platform", value: alert.platform.rawValue)
                    LabeledContent("Trigger", value: "\(alert.direction.displayName) \(alert.threshold.percentText)")
                    LabeledContent("Status", value: alert.isTriggered ? "Triggered" : alert.isEnabled ? "Active" : "Paused")
                    if let latestProbability = alert.latestProbability {
                        LabeledContent("Latest probability", value: latestProbability.percentText)
                    }
                }

                Section("Timeline") {
                    LabeledContent("Created", value: alert.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if let triggeredAt = alert.triggeredAt {
                        LabeledContent("Triggered", value: triggeredAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let deliveredAt = alert.notificationDeliveredAt {
                        LabeledContent("Notification sent", value: deliveredAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                if let market {
                    Section {
                        NavigationLink {
                            MarketDetailView(market: market, matchedMarket: marketStore.matchedMarket(for: market))
                        } label: {
                            Label("Open Market", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "Alert unavailable",
                    systemImage: "bell.slash",
                    description: Text("This alert may have been deleted.")
                )
            }
        }
        .navigationTitle("Alert")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    AlertsView()
        .environment(OddsightMarketStore())
        .environment(AppRouter())
}
