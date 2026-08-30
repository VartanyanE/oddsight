import SwiftUI

struct ScannerView: View {
    @State private var selectedSignalType: SignalType?
    private let signals = SampleOddsightData.signals

    private var filteredSignals: [OddsightSignal] {
        guard let selectedSignalType else { return signals }
        return signals.filter { $0.type == selectedSignalType }
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
                    ForEach(filteredSignals) { signal in
                        NavigationLink {
                            MarketDetailView(market: signal.market, matchedMarket: signal.matchedMarket)
                        } label: {
                            SignalRow(signal: signal)
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
}
