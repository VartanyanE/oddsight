import SwiftUI

struct AlertsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Ready For V1") {
                    AlertTemplateRow(
                        iconName: "arrow.left.arrow.right",
                        title: "Cross-market discrepancy",
                        detail: "Notify when a matched market differs by more than a selected threshold."
                    )
                    AlertTemplateRow(
                        iconName: "chart.xyaxis.line",
                        title: "Probability move",
                        detail: "Notify when probability moves sharply within a chosen time window."
                    )
                    AlertTemplateRow(
                        iconName: "waveform.path.ecg",
                        title: "Unusual volume",
                        detail: "Notify when volume rises above a historical baseline."
                    )
                }

                Section("Implementation Note") {
                    Text("Alerts will be evaluated server-side after ingestion, historical snapshots, and signal confidence rules are implemented.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Alerts")
        }
    }
}

private struct AlertTemplateRow: View {
    let iconName: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.cyan)
                .frame(width: 28, height: 28)
                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    AlertsView()
}
