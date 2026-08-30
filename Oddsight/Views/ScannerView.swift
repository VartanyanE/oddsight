import SwiftUI

struct ScannerView: View {
    @Environment(OddsightMarketStore.self) private var marketStore
    @State private var selectedSignalType: SignalType?

    private var filteredSignals: [OddsightSignal] {
        guard let selectedSignalType else { return marketStore.signals }
        return marketStore.signals.filter { $0.type == selectedSignalType }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Signal Type", selection: $selectedSignalType) {
                        Text("All").tag(nil as SignalType?)
                        ForEach(SignalType.allCases) { type in
                            Text(type.rawValue).tag(type as SignalType?)
                        }
                    }
                }

                Section("Ranked Signals") {
                    if filteredSignals.isEmpty {
                        ContentUnavailableView("No signals", systemImage: "scope", description: Text("Refresh live data or loosen the signal type filter."))
                    } else {
                        ForEach(filteredSignals) { signal in
                            NavigationLink {
                                MarketDetailView(market: signal.market, matchedMarket: signal.matchedMarket)
                            } label: {
                                SignalRow(signal: signal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Scanner")
        }
    }
}

#Preview {
    ScannerView()
        .environment(OddsightMarketStore())
}
