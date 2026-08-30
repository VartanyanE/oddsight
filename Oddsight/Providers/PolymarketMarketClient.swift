import Foundation

struct PolymarketMarketClient {
    private let gammaBaseURL = URL(string: "https://gamma-api.polymarket.com")!
    private let clobBaseURL = URL(string: "https://clob.polymarket.com")!
    private let session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func fetchActiveMarkets(limit: Int = 40) async throws -> [Market] {
        let gammaMarkets = try await fetchGammaMarkets(limit: limit)
        let tokenIds = gammaMarkets.flatMap { market in
            market.clobTokenIds?.values ?? []
        }
        let priceLookup = try? await fetchClobPrices(for: tokenIds)

        return gammaMarkets.compactMap { dto in
            dto.market(priceLookup: priceLookup ?? [:])
        }
    }

    private nonisolated func fetchGammaMarkets(limit: Int) async throws -> [PolymarketGammaMarketDTO] {
        var components = URLComponents(url: gammaBaseURL.appendingPathComponent("markets"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "active", value: "true"),
            URLQueryItem(name: "closed", value: "false"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "order", value: "volume24hr"),
            URLQueryItem(name: "ascending", value: "false")
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

        return try JSONDecoder().decode([PolymarketGammaMarketDTO].self, from: data)
    }

    private nonisolated func fetchClobPrices(for tokenIds: [String]) async throws -> [String: PolymarketTokenPrices] {
        let uniqueTokenIds = Array(Set(tokenIds)).filter { !$0.isEmpty }
        guard !uniqueTokenIds.isEmpty else { return [:] }

        let requests = uniqueTokenIds.flatMap { tokenId in
            [
                PolymarketPriceRequest(tokenId: tokenId, side: "BUY"),
                PolymarketPriceRequest(tokenId: tokenId, side: "SELL")
            ]
        }

        var request = URLRequest(url: clobBaseURL.appendingPathComponent("prices"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requests)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderClientError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw ProviderClientError.requestFailed(httpResponse.statusCode)
        }

        let payload = try JSONDecoder().decode([String: [String: FlexibleDouble]].self, from: data)
        return payload.mapValues { sideMap in
            PolymarketTokenPrices(
                bid: sideMap["BUY"]?.value,
                ask: sideMap["SELL"]?.value
            )
        }
    }
}

private struct PolymarketPriceRequest: Encodable {
    let tokenId: String
    let side: String

    enum CodingKeys: String, CodingKey {
        case tokenId = "token_id"
        case side
    }
}

private struct PolymarketTokenPrices {
    let bid: Double?
    let ask: Double?
}

nonisolated private struct PolymarketGammaMarketDTO: Decodable {
    let id: String
    let question: String
    let slug: String?
    let description: String?
    let resolutionSource: String?
    let endDate: String?
    let endDateIso: String?
    let active: Bool?
    let closed: Bool?
    let archived: Bool?
    let enableOrderBook: Bool?
    let acceptingOrders: Bool?
    let outcomes: FlexibleStringArray?
    let outcomePrices: FlexibleDoubleArray?
    let clobTokenIds: FlexibleStringArray?
    let volume24hr: FlexibleDouble?
    let volume: FlexibleDouble?
    let liquidity: FlexibleDouble?
    let liquidityClob: FlexibleDouble?
    let categories: [PolymarketCategoryDTO]?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case question
        case slug
        case description
        case resolutionSource
        case endDate
        case endDateIso
        case active
        case closed
        case archived
        case enableOrderBook
        case acceptingOrders
        case outcomes
        case outcomePrices
        case clobTokenIds
        case volume24hr
        case volume
        case liquidity
        case liquidityClob
        case categories
        case tags
    }

    nonisolated func market(priceLookup: [String: PolymarketTokenPrices]) -> Market? {
        guard active != false, closed != true, archived != true else {
            return nil
        }

        guard isYesNoMarket else {
            return nil
        }

        let tokenIds = clobTokenIds?.values ?? []
        let fallbackPrices = outcomePrices?.values ?? []
        let yesTokenId = tokenIds.first
        let noTokenId = tokenIds.dropFirst().first
        let yesTokenPrices = yesTokenId.flatMap { priceLookup[$0] }
        let noTokenPrices = noTokenId.flatMap { priceLookup[$0] }
        let fallbackYesPrice = fallbackPrices.first
        let fallbackNoPrice = fallbackPrices.dropFirst().first
        let yesBid = yesTokenPrices?.bid ?? fallbackYesPrice
        let yesAsk = yesTokenPrices?.ask ?? fallbackYesPrice
        let noBid = noTokenPrices?.bid ?? fallbackNoPrice
        let noAsk = noTokenPrices?.ask ?? fallbackNoPrice
        let probability = yesAsk.flatMap { ask in
            yesBid.map { bid in (bid + ask) / 2 }
        } ?? fallbackYesPrice ?? 0

        return Market(
            id: "polymarket-\(id)",
            title: question,
            normalizedQuestion: normalizedQuestion,
            platform: .polymarket,
            category: inferredCategory,
            probability: probability,
            bestBid: yesBid,
            bestAsk: yesAsk,
            noBestBid: noBid,
            noBestAsk: noAsk,
            volume24h: volume24hr?.value ?? volume?.value ?? 0,
            liquidity: liquidityClob?.value ?? liquidity?.value ?? 0,
            probabilityChange24h: 0,
            expirationDescription: endDate ?? endDateIso ?? "Unavailable",
            resolutionSummary: resolutionSummary,
            sourceURL: "https://polymarket.com/event/\(slug ?? id)"
        )
    }

    private nonisolated var inferredCategory: MarketCategory {
        let searchableParts = [question, description, resolutionSource]
            + (categories?.map(\.label) ?? [])
            + (tags ?? [])
        let searchable = searchableParts.compactMap { $0 }.joined(separator: " ").lowercased()

        if searchable.contains("election") || searchable.contains("president") || searchable.contains("politic") { return .politics }
        if searchable.contains("fed") || searchable.contains("rate") || searchable.contains("inflation") || searchable.contains("econom") { return .economics }
        if searchable.contains("bitcoin") || searchable.contains("crypto") || searchable.contains("ethereum") || searchable.contains("btc") { return .crypto }
        if searchable.contains("ai") || searchable.contains("tech") { return .technology }
        if searchable.contains("nfl") || searchable.contains("nba") || searchable.contains("mlb") || searchable.contains("sport") { return .sports }
        if searchable.contains("weather") || searchable.contains("hurricane") || searchable.contains("temperature") { return .weather }
        if searchable.contains("movie") || searchable.contains("music") || searchable.contains("entertainment") { return .entertainment }
        if searchable.contains("war") || searchable.contains("global") || searchable.contains("world") { return .worldEvents }
        return .other
    }

    private nonisolated var normalizedQuestion: String {
        [question, description, resolutionSource]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private nonisolated var isYesNoMarket: Bool {
        let normalizedOutcomes = (outcomes?.values ?? []).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return normalizedOutcomes.count == 2 && normalizedOutcomes[0] == "yes" && normalizedOutcomes[1] == "no"
    }

    private nonisolated var resolutionSummary: String {
        let summary = [description, resolutionSource]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        return summary.isEmpty ? "Resolution rules unavailable from this market response." : summary
    }
}

private struct PolymarketCategoryDTO: Decodable {
    let label: String?
    let name: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case name
    }
}

private struct FlexibleDouble: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self), let double = Double(string) {
            value = double
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected double or numeric string.")
        }
    }
}

private struct FlexibleDoubleArray: Decodable {
    let values: [Double]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubles = try? container.decode([Double].self) {
            values = doubles
        } else if let strings = try? container.decode([String].self) {
            values = strings.compactMap(Double.init)
        } else if let encoded = try? container.decode(String.self), let data = encoded.data(using: .utf8) {
            values = (try? JSONDecoder().decode([String].self, from: data).compactMap(Double.init)) ?? []
        } else {
            values = []
        }
    }
}

private struct FlexibleStringArray: Decodable {
    let values: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let strings = try? container.decode([String].self) {
            values = strings
        } else if let encoded = try? container.decode(String.self), let data = encoded.data(using: .utf8) {
            values = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        } else {
            values = []
        }
    }
}
