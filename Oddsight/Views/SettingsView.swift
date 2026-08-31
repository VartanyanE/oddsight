import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(OddsightMarketStore.self) private var marketStore

    private var diagnostics: AppDiagnostics {
        AppDiagnostics(store: marketStore)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Account & Plan") {
                    LabeledContent("Plan", value: marketStore.currentTier.displayName)
                    LabeledContent("Saved alerts", value: marketStore.alertUsageDescription)
                    Text("Purchases and account sign-in are not enabled in this build.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Notifications") {
                    LabeledContent("Permission", value: marketStore.notificationAuthorization.displayName)
                    notificationAction
                }

                Section("Data Diagnostics") {
                    LabeledContent("Data status", value: diagnostics.dataStatus)
                    LabeledContent("Markets", value: diagnostics.marketCount.formatted())
                    LabeledContent("Matches", value: diagnostics.matchCount.formatted())
                    LabeledContent("Signals shown", value: diagnostics.signalCount.formatted())
                    LabeledContent("Saved alerts", value: diagnostics.savedAlertCount.formatted())
                    LabeledContent("Last refresh", value: diagnostics.lastUpdatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Not yet")

                    if let providerError = diagnostics.providerError {
                        Text(providerError)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    Button("Refresh Market Data") {
                        Task { await marketStore.refreshMarkets() }
                    }
                    .disabled(marketStore.isLoading)
                }

                Section("Important Disclosures") {
                    Label("Oddsight provides market intelligence and research, not investment advice.", systemImage: "info.circle")
                    Text("Probabilities, matches, signals, and potential discrepancies may be delayed, incomplete, or incorrect. Verify resolution rules, executable prices, fees, liquidity, and settlement terms on the original platform before acting.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("No result or profit is guaranteed.")
                        .font(.footnote.weight(.semibold))
                }

                Section("About") {
                    LabeledContent("App", value: "Oddsight")
                    Text(AppMetadata.versionDescription)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .task { await marketStore.refreshNotificationAuthorization() }
        }
    }

    @ViewBuilder
    private var notificationAction: some View {
        switch marketStore.notificationAuthorization {
        case .notDetermined:
            Button("Enable Notifications") {
                Task { await marketStore.requestNotificationAuthorization() }
            }
        case .denied:
            Button("Open System Settings") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
        case .authorized:
            Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    SettingsView()
        .environment(OddsightMarketStore())
}
