# Oddsight API Design

## Principles

- REST-first, versioned under `/v1`.
- Shape endpoints around mobile workflows.
- Return freshness, confidence, and data-quality fields.
- Keep scanner calculations server-side.
- Avoid provider-specific response leakage except source links and attribution.
- Support pagination on all list endpoints.

## Authentication

Public browsing may be allowed early, but alert creation requires authentication.

Use bearer tokens:

```http
Authorization: Bearer <token>
```

Initial auth endpoints can be deferred until the product needs persistent users. For local MVP, a development auth shim is acceptable if it is isolated from production code.

## Common Response Metadata

List responses should include:

```json
{
  "data": [],
  "pagination": {
    "cursor": "next_cursor",
    "hasMore": true
  },
  "meta": {
    "generatedAt": "2026-08-29T12:00:00Z"
  }
}
```

Market and signal objects should include:

- `observedAt`
- `ingestedAt`
- `freshnessSeconds`
- `dataQuality`

## Endpoints

## GET `/v1/discover`

Purpose: first screen summary.

Query parameters:

- `category`
- `platform`
- `limit`

Returns:

- Top signals.
- Biggest probability movers.
- Highest-volume markets.
- New markets.
- Top discrepancies.

This endpoint exists because the mobile Discover screen should not need to orchestrate many calls.

## GET `/v1/scanner`

Purpose: main scanner workflow.

Query parameters:

- `signalType`
- `platform`
- `category`
- `expiresBefore`
- `expiresAfter`
- `minVolume`
- `minLiquidity`
- `minDiscrepancy`
- `minArbitrageReturn`
- `minMatchConfidence`
- `sort`
- `cursor`
- `limit`

Returns scanner rows:

```json
{
  "id": "signal_id",
  "signalType": "cross_market_discrepancy",
  "severity": "high",
  "confidence": 0.91,
  "market": {
    "id": "market_id",
    "title": "Fed cuts rates in September?",
    "category": "Economics"
  },
  "matchedMarket": {
    "id": "matched_market_id",
    "platforms": ["kalshi", "polymarket"],
    "confidence": 0.94,
    "status": "high_confidence"
  },
  "metric": {
    "label": "Difference",
    "value": 0.07,
    "unit": "probability_points"
  },
  "freshnessSeconds": 42,
  "detectedAt": "2026-08-29T12:00:00Z"
}
```

## GET `/v1/markets`

Purpose: market browsing and search.

Query parameters:

- `q`
- `platform`
- `category`
- `status`
- `expiresBefore`
- `expiresAfter`
- `minVolume`
- `cursor`
- `limit`

Returns normalized markets with latest snapshot summaries.

## GET `/v1/markets/:marketId`

Purpose: market detail screen.

Returns:

- Normalized market fields.
- Provider source fields.
- Contracts.
- Latest snapshot.
- Recent history.
- Related matches.
- Signals.
- Source URL.
- Data freshness.

## GET `/v1/markets/:marketId/history`

Purpose: charts.

Query parameters:

- `range`
- `bucket`

Returns historical aggregate buckets, not raw snapshots by default.

## GET `/v1/signals`

Purpose: signal feed independent of scanner.

Query parameters:

- `type`
- `marketId`
- `matchedMarketId`
- `severity`
- `status`
- `cursor`
- `limit`

Use this for market detail and alert debugging. The Scanner endpoint remains the optimized ranked workflow.

## GET `/v1/signals/:signalId`

Purpose: inspect one signal.

Returns:

- Explanation.
- Supporting data.
- Formula inputs.
- Related market and match.
- Freshness and confidence.

## GET `/v1/matches`

Purpose: browse matched markets.

Query parameters:

- `status`
- `minConfidence`
- `category`
- `platform`
- `cursor`
- `limit`

Returns summary match rows.

## GET `/v1/matches/:matchedMarketId`

Purpose: matched market detail.

Returns:

- Linked markets.
- Price comparison.
- Contract comparison.
- Match assessment.
- Settlement differences.
- Related signals.

## POST `/v1/alerts`

Purpose: create an alert.

Request:

```json
{
  "name": "Fed discrepancy above 6 points",
  "alertType": "cross_market_discrepancy",
  "scopeType": "matched_market",
  "scopeId": "matched_market_id",
  "conditions": {
    "minDiscrepancy": 0.06,
    "minMatchConfidence": 0.9
  },
  "deliveryChannels": ["in_app"]
}
```

Server validates:

- User entitlement.
- Supported alert type.
- Valid condition fields.
- Scope exists.

## GET `/v1/alerts`

Purpose: alerts screen.

Returns active and paused alerts for the authenticated user.

## PATCH `/v1/alerts/:alertId`

Purpose: update alert status or conditions.

Only the owner may update.

## DELETE `/v1/alerts/:alertId`

Purpose: delete or archive alert.

Prefer soft delete if trigger history matters.

## GET `/v1/providers/status`

Purpose: internal and user-visible data health.

Returns:

- Provider status.
- Last successful ingestion.
- Current lag.
- Known degraded capabilities.

This can power subtle UI freshness warnings.

## Error Format

Use a consistent error shape:

```json
{
  "error": {
    "code": "INVALID_ALERT_CONDITION",
    "message": "The alert condition is not supported.",
    "details": {}
  }
}
```

## Sorting

Scanner sort options:

- `interesting`
- `newest`
- `severity`
- `discrepancy`
- `volume`
- `movement`
- `expiration`

Default should be `interesting`, backed by explicit ranking logic. Do not expose an Oddsight Score until the methodology is defensible.

## API Risks

- Overly generic endpoints will force the mobile app to assemble scanner logic client-side.
- Exposing raw provider shapes can make future provider changes painful.
- Alert APIs should not ship before server-side evaluation exists.
- Real-time push or websockets should wait until polling-based freshness is understood.
