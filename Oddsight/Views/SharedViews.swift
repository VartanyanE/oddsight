import SwiftUI

struct OddsightLogoMark: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.08, blue: 0.12),
                            Color(red: 0.02, green: 0.17, blue: 0.19)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            EyeShape()
                .stroke(.cyan.opacity(0.9), lineWidth: max(2, size * 0.06))
                .frame(width: size * 0.66, height: size * 0.42)

            Circle()
                .fill(.cyan)
                .frame(width: size * 0.16, height: size * 0.16)

            SparklineShape()
                .stroke(.green, style: StrokeStyle(lineWidth: max(1.6, size * 0.045), lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.56, height: size * 0.34)
                .offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Oddsight")
    }
}

private struct EyeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private struct SparklineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY * 0.70))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.maxY * 0.62))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.maxY * 0.38))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY * 0.48))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.18))
        return path
    }
}

struct OddsightHeaderView: View {
    let subtitle: String

    var body: some View {
        Section {
            HStack(spacing: 14) {
                OddsightLogoMark(size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Oddsight")
                        .font(.title2.weight(.bold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PlatformBadge: View {
    let platform: PredictionPlatform

    var body: some View {
        Text(platform.rawValue)
            .font(.caption.weight(.semibold))
            .foregroundStyle(platform.tint)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(platform.tint.opacity(0.12), in: Capsule())
    }
}

struct MarketRow: View {
    let market: Market

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(market.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(market.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                PlatformBadge(platform: market.platform)
            }

            HStack(spacing: 8) {
                MetricPill(title: "Prob", value: market.probability.percentText, tint: .cyan)
                MetricPill(title: "24h", value: market.probabilityChange24h.signedPointsText, tint: market.probabilityChange24h >= 0 ? .green : .red)
                MetricPill(title: "Vol", value: market.volume24h.compactDollarText, tint: .primary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct SignalRow: View {
    let signal: OddsightSignal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(signal.severity.tint)
                    .frame(width: 28, height: 28)
                    .background(signal.severity.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 7))

                VStack(alignment: .leading, spacing: 5) {
                    Text(signal.title)
                        .font(.headline)
                    Text(signal.market.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(signal.metricValue)
                        .font(.headline.weight(.semibold))
                    Text(signal.metricLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text(signal.type.rawValue)
                Spacer()
                Text("Confidence \(signal.confidence.percentText)")
                Text(signal.detectedDescription)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var iconName: String {
        switch signal.type {
        case .crossMarketDiscrepancy:
            return "arrow.left.arrow.right"
        case .potentialArbitrage:
            return "sum"
        case .probabilityMove:
            return "chart.xyaxis.line"
        case .volumeSpike:
            return "waveform.path.ecg"
        case .liquidityChange:
            return "drop.degreesign"
        case .newMatchedMarket:
            return "link"
        }
    }
}

extension Double {
    nonisolated var percentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }

    nonisolated var pointsText: String {
        let points = self * 100
        return points.formatted(.number.precision(.fractionLength(0))) + " pts"
    }

    nonisolated var signedPointsText: String {
        let points = self * 100
        return points.formatted(.number.precision(.fractionLength(0)).sign(strategy: .always())) + " pts"
    }

    nonisolated var compactDollarText: String {
        formatted(.currency(code: "USD").notation(.compactName).precision(.fractionLength(0)))
    }
}
