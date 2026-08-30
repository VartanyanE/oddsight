# Provider Capability Verification

Last verified: 2026-08-30.

This document records the current API capabilities that matter for the Oddsight Scanner MVP. It should be refreshed before building production ingestion because provider APIs, rate limits, and field semantics can change.

## Sources Checked

Kalshi official docs:

- [Kalshi Quick Start: Market Data](https://docs.kalshi.com/getting_started/quick_start_market_data)
- [Kalshi Get Markets](https://docs.kalshi.com/api-reference/market/get-markets)
- [Kalshi Get Market](https://docs.kalshi.com/api-reference/market/get-market)
- [Kalshi Get Market Orderbook](https://docs.kalshi.com/api-reference/market/get-market-orderbook)
- [Kalshi Get Trades](https://docs.kalshi.com/api-reference/market/get-trades)
- [Kalshi Market Candlesticks](https://docs.kalshi.com/api-reference/market/get-market-candlesticks)
- [Kalshi WebSocket Quick Start](https://docs.kalshi.com/getting_started/quick_start_websockets)

Polymarket official docs:

- [Polymarket API Overview](https://docs.polymarket.com/api-reference/predictions/overview)
- [Polymarket Prices and Order Books](https://docs.polymarket.com/market-data/prices-order-books)
- [Polymarket Real-Time Data](https://docs.polymarket.com/market-data/realtime-data)
- [Polymarket Price History](https://docs.polymarket.com/api-reference/markets/get-prices-history)

Live public endpoint checks:

- `GET https://external-api.kalshi.com/trade-api/v2/markets?limit=1&status=open`
- `GET https://gamma-api.polymarket.com/markets?active=true&closed=false&limit=1`
- `GET https://clob.polymarket.com/markets?closed=false&limit=1`

## High-Level Capability Matrix

| Capability | Kalshi | Polymarket | MVP Impact |
| --- | --- | --- | --- |
| Market discovery | Yes, REST `/markets` and `/events` | Yes, Gamma API markets/events | Required for Milestones 3-5 |
| Active/open market filtering | Yes | Yes, but endpoint semantics differ | Normalize statuses carefully |
| Market title/question | Yes | Yes | Required |
| Resolution rules | Yes, market rules fields | Yes, description/resolution fields | Required for matching |
| Category/tags | Yes, series/event/category data | Yes, tags/events/categories | Useful for filters and matching |
| Last trade price | Yes | Yes | Useful, but not executable |
| Best bid/ask | Yes in market payload and derivable from order book | Yes through CLOB pricing/order books | Required for credible discrepancy signals |
| Order book | Yes, bid levels for YES and NO sides | Yes, CLOB bids and asks by token ID | Required for executable-price work |
| Batch order books | Yes | Yes | Important for scalable scanner refresh |
| Volume | Yes | Yes | Required for volume screens |
| Rolling volume windows | Yes for at least 24h in observed payload | Yes for 24h/1w/1m/1y in observed Gamma payload | Useful, but definitions need validation |
| Liquidity | Yes | Yes | Useful, but definitions differ |
| Open interest | Yes in observed payload | Available through documented endpoint | Useful |
| Trades | Yes, documented trades endpoint | Yes, documented trades endpoints | Enables large-trade signals if rate limits allow |
| Historical candles/prices | Yes, candlesticks | Yes, price history | Useful, but Oddsight should still store its own history |
| Public WebSocket market data | Requires authenticated WebSocket session | Market stream documented | Later milestone |
| Trading/order placement | Yes | Yes | Out of scope |

## Kalshi Findings

Kalshi provides public REST market-data endpoints from:

```text
https://external-api.kalshi.com/trade-api/v2
```

The official quick start says several public endpoints do not require API keys for market data. The live market check returned open market data without authentication.

Observed useful market fields:

- `ticker`
- `event_ticker`
- `market_type`
- `title`
- `yes_sub_title`
- `no_sub_title`
- `status`
- `created_time`
- `updated_time`
- `open_time`
- `close_time`
- `expiration_time`
- `expected_expiration_time`
- `latest_expiration_time`
- `yes_bid_dollars`
- `yes_ask_dollars`
- `no_bid_dollars`
- `no_ask_dollars`
- `last_price_dollars`
- `previous_price_dollars`
- `volume_fp`
- `volume_24h_fp`
- `liquidity_dollars`
- `open_interest_fp`
- `rules_primary`
- `rules_secondary`
- `settlement_timer_seconds`

Important order-book detail: Kalshi order books return active bid orders for both YES and NO sides rather than direct asks. A YES bid at price `X` is economically equivalent to a NO ask at `1 - X`; the inverse is true for NO bids and YES asks. Oddsight should preserve native bid levels and derive executable asks in a tested calculation layer.

Kalshi WebSocket market-data channels exist for ticker, trade, order book, and lifecycle updates, but the WebSocket connection itself requires authentication. This makes REST polling the safer MVP path.

## Polymarket Findings

Polymarket separates APIs by purpose:

| API | Base URL | Purpose |
| --- | --- | --- |
| Gamma API | `https://gamma-api.polymarket.com` | Discover events and markets, fetch metadata |
| CLOB API | `https://clob.polymarket.com` | Live market state, prices, order books, trades, orders |
| Data API | `https://data-api.polymarket.com` | Account and market activity |
| Realtime streams | Documented WebSocket streams | Market, account, sports, and RFQ events |

Observed useful Gamma market fields:

- `id`
- `question`
- `conditionId`
- `slug`
- `description`
- `resolutionSource`
- `startDate`
- `endDate`
- `active`
- `closed`
- `archived`
- `restricted`
- `enableOrderBook`
- `acceptingOrders`
- `outcomes`
- `outcomePrices`
- `clobTokenIds`
- `volume`
- `volume24hr`
- `volume1wk`
- `volume1mo`
- `volume1yr`
- `liquidity`
- `volumeClob`
- `liquidityClob`
- `makerBaseFee`
- `takerBaseFee`
- `orderPriceMinTickSize`
- `orderMinSize`
- `events`

Important Polymarket modeling detail: CLOB pricing is token-based. Each outcome has a token ID, and order-book/pricing requests operate on token IDs. Oddsight should normalize Polymarket outcomes into contracts before calculating market-level bid/ask comparisons.

The CLOB market endpoint returned older closed markets when queried naively with `closed=false`, so the first ingestion implementation should prefer Gamma for discovery and use CLOB by explicit token IDs for live pricing/order books.

## MVP Provider Strategy

### Kalshi First Pass

Use REST polling:

1. `GET /markets` filtered to active/open markets.
2. `GET /markets/{ticker}` for detail when needed.
3. `GET /markets/{ticker}/orderbook` for scanner candidates and active details.
4. `GET /trades` only after basic snapshots work.
5. Candlesticks only for bootstrap history, not as a substitute for Oddsight snapshots.

### Polymarket First Pass

Use Gamma plus CLOB:

1. Gamma markets for discovery, rules, tags, volumes, liquidity, and token IDs.
2. CLOB order-book/pricing endpoints by token ID for executable price data.
3. CLOB price history only for chart bootstrap or backfill.
4. Realtime market stream after polling quality is proven.

Current app implementation:

- Uses `mve_filter=exclude` to avoid Kalshi multivariate combo markets.
- Paginates Kalshi market discovery and keeps active markets with usable price/activity fields instead of relying on the first newest page.
- Includes Kalshi subtitles and rules in normalized text because thresholds are often not present in the title.
- Uses Gamma markets for active market discovery.
- Filters to YES/NO outcomes only because the current native model and UI label contracts as YES and NO.
- Uses CLOB `/prices` batch requests for token-level BUY and SELL prices when `clobTokenIds` are available.
- Falls back to Gamma `outcomePrices` when CLOB price hydration fails.

## Signal Feasibility

| Signal | Feasible For MVP? | Notes |
| --- | --- | --- |
| Cross-market discrepancy | Yes | Requires normalized bid/ask semantics and match confidence |
| Potential arbitrage | Limited | Only use with executable asks, compatible contract sizes, and high match confidence |
| Probability movement | Yes | Stronger after Oddsight stores snapshots |
| Volume spike | Partial | Provider rolling volume exists, but baseline needs Oddsight history |
| Large trade | Later | Both providers expose trade surfaces, but rate limits and completeness need implementation tests |
| Liquidity change | Partial | Use cautiously because provider liquidity definitions differ |
| New matched market | Yes | Available once matching pipeline exists |

## Implementation Risks

- Kalshi status values in docs include `open`, while the observed live payload used `active`; normalization must handle both provider wording and documented wording.
- Kalshi order books require tested YES/NO bid-to-ask derivation.
- Polymarket discovery and CLOB live state are separate surfaces; missing token IDs or `enableOrderBook=false` should disable executable signals.
- Polymarket Gamma fields such as `outcomes`, `outcomePrices`, and `clobTokenIds` may be JSON-encoded strings, not native arrays.
- Provider volume and liquidity definitions are not directly comparable without provider-specific metadata.
- WebSocket support should be delayed until REST polling and snapshot storage are stable.

## Next Implementation Step

Build a small Swift domain calculation layer before networking:

- Price representation in decimal dollars.
- YES/NO bid-to-ask derivation for Kalshi.
- Cross-market discrepancy calculation.
- Potential arbitrage gross calculation.
- Data-quality flags for last price versus midpoint versus executable bid/ask.
- Unit tests for all critical calculations.

This gives the app a trustworthy calculation core before it consumes live provider data.
