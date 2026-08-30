# Oddsight Data Model

## Principles

- Preserve provider identity and raw timestamps.
- Normalize only what Oddsight understands.
- Distinguish market, contract, event, and snapshot.
- Store price fields with explicit semantics.
- Treat missing data as missing, not zero.
- Store match reasoning and confidence, not just match status.
- Design for historical snapshots without storing every raw response forever.

## Core Entities

## Provider

Represents an external prediction-market platform.

Fields:

- `id`
- `code` such as `kalshi` or `polymarket`
- `displayName`
- `baseUrl`
- `capabilities`
- `status`
- `createdAt`
- `updatedAt`

Important indexes:

- Unique `code`.

## ProviderMarket

Stores provider-native market identity and metadata. This preserves source data even when Oddsight normalization changes.

Fields:

- `id`
- `providerId`
- `providerMarketId`
- `providerEventId`
- `rawTitle`
- `rawDescription`
- `rawRules`
- `rawCategory`
- `rawStatus`
- `sourceUrl`
- `firstSeenAt`
- `lastSeenAt`
- `providerUpdatedAt`
- `rawMetadata` JSONB

Important indexes:

- Unique `(providerId, providerMarketId)`.
- `(providerId, rawStatus)`.
- `(lastSeenAt)`.

## Event

Represents a normalized real-world event or topic grouping. An Event may contain multiple markets.

Fields:

- `id`
- `canonicalTitle`
- `normalizedSubject`
- `category`
- `subcategory`
- `eventStartAt`
- `eventEndAt`
- `createdAt`
- `updatedAt`

Important indexes:

- `(category, eventEndAt)`.
- Full-text index on `canonicalTitle`.

## Market

Represents an Oddsight-normalized question from one provider.

Fields:

- `id`
- `providerMarketId`
- `eventId`
- `canonicalQuestion`
- `normalizedQuestion`
- `category`
- `status`
- `marketType`
- `outcomeType`
- `expirationAt`
- `settlementAt`
- `resolutionSource`
- `resolutionSummary`
- `timezone`
- `isActive`
- `createdAt`
- `updatedAt`

Important indexes:

- `(isActive, expirationAt)`.
- `(category, isActive)`.
- `(eventId)`.
- Full-text index on `normalizedQuestion`.

## Contract

Represents an outcome within a market. Binary markets generally have YES and NO contracts.

Fields:

- `id`
- `marketId`
- `providerContractId`
- `side`
- `label`
- `normalizedOutcome`
- `payoutCurrency`
- `payoutAmount`
- `createdAt`
- `updatedAt`

Important indexes:

- `(marketId, side)`.
- Unique `(marketId, providerContractId)` where available.

## MarketSnapshot

Stores point-in-time market pricing and activity metrics.

Fields:

- `id`
- `marketId`
- `observedAt`
- `ingestedAt`
- `lastTradePrice`
- `midPrice`
- `bestBid`
- `bestAsk`
- `impliedProbability`
- `volume`
- `volume24h`
- `openInterest`
- `liquidity`
- `priceChange1h`
- `priceChange24h`
- `sourceFreshnessSeconds`
- `dataQuality`
- `rawMetadata` JSONB

Important indexes:

- `(marketId, observedAt DESC)`.
- `(observedAt DESC)`.
- `(dataQuality)`.

Notes:

- Do not assume `lastTradePrice`, `midPrice`, and executable price are equivalent.
- Store provider values separately if they use different units or meanings.

## ContractSnapshot

Stores contract-level bid/ask and price state when available.

Fields:

- `id`
- `contractId`
- `observedAt`
- `bestBid`
- `bestAsk`
- `midPrice`
- `lastTradePrice`
- `bidSize`
- `askSize`
- `volume`
- `openInterest`
- `rawMetadata` JSONB

Important indexes:

- `(contractId, observedAt DESC)`.

## OrderBookSnapshot

Stores limited depth order book snapshots when provider data supports it.

Fields:

- `id`
- `marketId`
- `contractId`
- `observedAt`
- `ingestedAt`
- `bids` JSONB
- `asks` JSONB
- `depthLevelCount`
- `rawMetadata` JSONB

Important indexes:

- `(marketId, observedAt DESC)`.
- `(contractId, observedAt DESC)`.

Retention should be shorter than aggregate market snapshots unless order book history proves valuable.

## MatchedMarket

Represents a relationship between two or more markets believed to describe the same or related economic event.

Fields:

- `id`
- `primaryMarketId`
- `comparisonMarketId`
- `status`
- `confidence`
- `matchType`
- `createdBy`
- `createdAt`
- `updatedAt`
- `reviewedAt`
- `reviewedBy`

Statuses:

- `verified`
- `high_confidence`
- `possible`
- `rejected`
- `needs_review`

Important indexes:

- Unique `(primaryMarketId, comparisonMarketId)`.
- `(status, confidence DESC)`.

## MatchAssessment

Stores the evidence behind a match decision.

Fields:

- `id`
- `matchedMarketId`
- `assessmentVersion`
- `eventSimilarity`
- `dateSimilarity`
- `outcomeSimilarity`
- `thresholdSimilarity`
- `resolutionSimilarity`
- `settlementTimingSimilarity`
- `resolutionSourceSimilarity`
- `overallConfidence`
- `reasons` JSONB
- `risks` JSONB
- `modelUsed`
- `aiCostCents`
- `createdAt`

Important indexes:

- `(matchedMarketId, createdAt DESC)`.
- `(assessmentVersion)`.

## Signal

Represents an Oddsight-detected market intelligence event.

Fields:

- `id`
- `signalType`
- `marketId`
- `matchedMarketId`
- `providerId`
- `severity`
- `confidence`
- `observedValue`
- `baselineValue`
- `absoluteDifference`
- `percentageDifference`
- `windowSeconds`
- `explanation`
- `supportingData` JSONB
- `status`
- `detectedAt`
- `expiresAt`
- `createdAt`

Important indexes:

- `(status, detectedAt DESC)`.
- `(signalType, severity DESC, detectedAt DESC)`.
- `(marketId, detectedAt DESC)`.
- `(matchedMarketId, detectedAt DESC)`.

## Alert

Stores a user-defined condition. Evaluation runs server-side.

Fields:

- `id`
- `userId`
- `name`
- `alertType`
- `scopeType`
- `scopeId`
- `conditions` JSONB
- `deliveryChannels` JSONB
- `status`
- `lastEvaluatedAt`
- `lastTriggeredAt`
- `createdAt`
- `updatedAt`

Important indexes:

- `(userId, status)`.
- `(alertType, status)`.
- `(lastEvaluatedAt)`.

## AlertTrigger

Stores alert trigger history.

Fields:

- `id`
- `alertId`
- `signalId`
- `triggeredAt`
- `payload` JSONB
- `deliveryStatus`
- `deliveryAttempts`

Important indexes:

- `(alertId, triggeredAt DESC)`.

## User

Fields:

- `id`
- `email`
- `displayName`
- `authProvider`
- `entitlementTier`
- `createdAt`
- `updatedAt`
- `lastSeenAt`

Important indexes:

- Unique `email`.
- `(entitlementTier)`.

## Entitlement

Optional early table if subscriptions are not implemented but feature gates need structure.

Fields:

- `id`
- `userId`
- `tier`
- `source`
- `status`
- `startsAt`
- `endsAt`
- `metadata` JSONB

## HistoricalAggregate

Stores rolled-up history for charts and baselines.

Fields:

- `id`
- `marketId`
- `bucketSize`
- `bucketStartAt`
- `openProbability`
- `highProbability`
- `lowProbability`
- `closeProbability`
- `volume`
- `liquidityMin`
- `liquidityMax`
- `liquidityClose`
- `snapshotCount`

Important indexes:

- Unique `(marketId, bucketSize, bucketStartAt)`.
- `(bucketSize, bucketStartAt DESC)`.

## Relationship Summary

- Provider has many ProviderMarkets.
- ProviderMarket maps to one normalized Market.
- Event has many Markets.
- Market has many Contracts.
- Market has many MarketSnapshots.
- Contract has many ContractSnapshots.
- Market may have many OrderBookSnapshots.
- MatchedMarket links two Markets.
- MatchedMarket has many MatchAssessments.
- Signal belongs to a Market and optionally a MatchedMarket.
- User has many Alerts.
- Alert has many AlertTriggers.

## Data Modeling Risks

- Some providers may represent multi-outcome markets differently from binary markets.
- Provider volume and liquidity definitions may not be comparable without normalization notes.
- Contract sizing and payout rules can differ.
- Settlement criteria must be modeled deeply enough for matching, but not overfit before provider data is verified.
