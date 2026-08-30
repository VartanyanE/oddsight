import Foundation

enum ProviderClientError: LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provider URL could not be created."
        case .invalidResponse:
            return "The provider returned an invalid response."
        case .requestFailed(let statusCode):
            return "The provider request failed with status \(statusCode)."
        }
    }
}

struct KalshiMarketClient {
    private let baseURL = URL(string: "https://external-api.kalshi.com/trade-api/v2")!
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func fetchActiveMarkets(limit: Int = 50) async throws -> [Market] {
        var components = URLComponents(url: baseURL.appendingPathComponent("markets"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "status", value: "open")
        ]

        guard let url = components?.url else {
            throw ProviderClientError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ProviderClientError.requestFailed(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(KalshiMarketsResponse.self, from: data)

        return payload.markets.compactMap { $0.market }
    }
}

nonisolated private struct KalshiMarketsResponse: Decodable {
    let markets: [KalshiMarketDTO]
}

nonisolated private struct KalshiMarketDTO: Decodable {
    let ticker: String
    let title: String
    let marketType: String?
    let status: String?
    let closeTime: String?
    let expirationTime: String?
    let expectedExpirationTime: String?
    let yesBidDollars: String?
    let yesAskDollars: String?
    let noBidDollars: String?
    let noAskDollars: String?
    let lastPriceDollars: String?
    let previousPriceDollars: String?
    let volume24h: String?
    let liquidityDollars: String?
    let rulesPrimary: String?
    let rulesSecondary: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case ticker
        case title
        case marketType = "market_type"
        case status
        case closeTime = "close_time"
        case expirationTime = "expiration_time"
        case expectedExpirationTime = "expected_expiration_time"
        case yesBidDollars = "yes_bid_dollars"
        case yesAskDollars = "yes_ask_dollars"
        case noBidDollars = "no_bid_dollars"
        case noAskDollars = "no_ask_dollars"
        case lastPriceDollars = "last_price_dollars"
        case previousPriceDollars = "previous_price_dollars"
        case volume24h = "volume_24h_fp"
        case liquidityDollars = "liquidity_dollars"
        case rulesPrimary = "rules_primary"
        case rulesSecondary = "rules_secondary"
        case category
    }

    nonisolated var market: Market? {
        guard marketType == nil || marketType == "binary" else {
            return nil
        }

        let yesBid = yesBidDollars.decimalPrice
        let yesAsk = yesAskDollars.decimalPrice
        let noBid = noBidDollars.decimalPrice
        let noAsk = noAskDollars.decimalPrice
        let lastPrice = lastPriceDollars.decimalPrice
        let previousPrice = previousPriceDollars.decimalPrice
        let probability = yesAsk.flatMap { ask in
            yesBid.map { bid in (bid + ask) / 2 }
        } ?? lastPrice ?? 0

        return Market(
            id: "kalshi-\(ticker)",
            title: title,
            normalizedQuestion: title,
            platform: .kalshi,
            category: category.marketCategory,
            probability: probability,
            bestBid: yesBid,
            bestAsk: yesAsk,
            noBestBid: noBid,
            noBestAsk: noAsk,
            volume24h: volume24h.decimalNumber ?? 0,
            liquidity: liquidityDollars.decimalNumber ?? 0,
            probabilityChange24h: probability - (previousPrice ?? probability),
            expirationDescription: expirationTime ?? expectedExpirationTime ?? closeTime ?? "Unavailable",
            resolutionSummary: resolutionSummary,
            sourceURL: "https://kalshi.com/markets/\(ticker)"
        )
    }

    private var resolutionSummary: String {
        let rules = [rulesPrimary, rulesSecondary]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return rules.first ?? "Resolution rules unavailable from this market list response."
    }
}

private extension Optional where Wrapped == String {
    nonisolated var decimalNumber: Double? {
        guard let self else { return nil }
        return Double(self)
    }

    nonisolated var decimalPrice: Double? {
        guard let value = decimalNumber else { return nil }
        return (0...1).contains(value) ? value : nil
    }

    nonisolated var marketCategory: MarketCategory {
        guard let value = self?.lowercased() else { return .other }

        if value.contains("politic") || value.contains("election") { return .politics }
        if value.contains("econom") || value.contains("fed") || value.contains("inflation") { return .economics }
        if value.contains("crypto") || value.contains("bitcoin") || value.contains("ethereum") { return .crypto }
        if value.contains("tech") || value.contains("ai") { return .technology }
        if value.contains("sport") || value.contains("nfl") || value.contains("nba") || value.contains("mlb") { return .sports }
        if value.contains("weather") || value.contains("temperature") { return .weather }
        if value.contains("entertainment") || value.contains("movie") { return .entertainment }
        if value.contains("world") || value.contains("global") { return .worldEvents }
        return .other
    }
}
