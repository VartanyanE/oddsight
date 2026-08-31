import SwiftUI

struct DataStatusView: View {
    let state: OddsightMarketStore.DataSourceState
    let lastUpdatedAt: Date?
    let errorMessage: String?
    let marketCount: Int
    let matchCount: Int
    let signalCount: Int
    let refreshAction: () async -> Void

    var body: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    Task {
                        await refreshAction()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(isLoading)
            }
        }
    }

    private var iconName: String {
        switch state {
        case .initial, .sampleFallback:
            return "shippingbox"
        case .loading:
            return "arrow.triangle.2.circlepath"
        case .partial:
            return "exclamationmark.triangle"
        case .live:
            return "checkmark.seal"
        }
    }

    private var isLoading: Bool {
        state == .loading
    }

    private var iconColor: Color {
        switch state {
        case .partial, .sampleFallback:
            return .orange
        case .live:
            return .green
        case .initial, .loading:
            return .secondary
        }
    }

    private var title: String {
        switch state {
        case .initial:
            return "Sample data"
        case .loading:
            return "Refreshing providers"
        case .live:
            return "Live provider data"
        case .partial(let failedProviders):
            return "Partial live data · \(providerNames(failedProviders)) unavailable"
        case .sampleFallback:
            return "Sample fallback"
        }
    }

    private var subtitle: String? {
        if let errorMessage {
            return errorMessage
        }
        if let lastUpdatedAt {
            return "Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened)) · \(marketCount) markets · \(matchCount) matches · \(signalCount) signals"
        }
        return "Tap refresh to load public Kalshi and Polymarket data."
    }

    private func providerNames(_ providers: [PredictionPlatform]) -> String {
        providers.map(\.rawValue).joined(separator: ", ")
    }
}
