# Oddsight

Oddsight is a mobile-first prediction-market intelligence platform. The initial product is Oddsight Scanner, a tool for discovering pricing discrepancies, unusual activity, market movement, and potentially actionable opportunities across prediction markets.

## Current Direction

The project currently uses a native SwiftUI iOS app. The first implementation slice is a local sample-data app shell with four tabs:

- Discover
- Scanner
- Market
- Alerts

Backend ingestion, market matching, signal evaluation, alerts, and provider integrations are intentionally not implemented yet.

The app now includes public Kalshi and Polymarket REST clients for live market browsing in Discover and Market. Polymarket discovery is limited to YES/NO markets and hydrates top-of-book prices through the CLOB `/prices` endpoint when token IDs are available. Scanner signals are generated from conservative live match candidates when provider data is available, with sample signals used only during fallback.

## Planning Docs

Start with:

- `PRODUCT.md`
- `ARCHITECTURE.md`
- `DATA_MODEL.md`
- `API_DESIGN.md`
- `MARKET_MATCHING.md`
- `SIGNAL_ENGINE.md`
- `HISTORICAL_DATA.md`
- `SECURITY.md`
- `ROADMAP.md`
- `DECISIONS.md`

## Next Milestones

1. Finalize the SwiftUI-first architecture decision.
2. Verify Kalshi and Polymarket API capabilities.
3. Add tested domain calculations for discrepancies and potential arbitrage.
4. Build the first provider-backed market browser.
5. Add deeper match reasoning and settlement-rule review.

Current provider capability notes live in `docs/PROVIDER_CAPABILITIES.md`.
