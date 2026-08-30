import SwiftUI

struct DataStatusView: View {
    let isLoading: Bool
    let isUsingSampleFallback: Bool
    let lastUpdatedAt: Date?
    let errorMessage: String?
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
        if isLoading { return "arrow.triangle.2.circlepath" }
        if errorMessage != nil { return "exclamationmark.triangle" }
        return isUsingSampleFallback ? "shippingbox" : "checkmark.seal"
    }

    private var iconColor: Color {
        if errorMessage != nil { return .orange }
        return isUsingSampleFallback ? .secondary : .green
    }

    private var title: String {
        if isLoading { return "Refreshing providers" }
        if isUsingSampleFallback { return "Sample data" }
        return "Live provider data"
    }

    private var subtitle: String? {
        if let errorMessage {
            return errorMessage
        }
        if let lastUpdatedAt {
            return "Updated \(lastUpdatedAt.formatted(date: .omitted, time: .shortened))"
        }
        return "Tap refresh to load public Kalshi and Polymarket data."
    }
}
