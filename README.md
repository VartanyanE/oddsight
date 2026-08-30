# Oddsight

Oddsight is a mobile-first prediction-market intelligence platform. The initial product is Oddsight Scanner, a tool for discovering pricing discrepancies, unusual activity, market movement, and potentially actionable opportunities across prediction markets.

## Current Direction

The project currently uses a native SwiftUI iOS app. The first implementation slice is a local sample-data app shell with four tabs:

- Discover
- Scanner
- Market
- Alerts

Backend ingestion, market matching, signal evaluation, alerts, and provider integrations are intentionally not implemented yet.

The app now includes a first public Kalshi REST client for live market browsing in Discover and Market. Scanner signals still use sample data until Polymarket live data and automated matching are implemented.

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
5. Add Polymarket discovery and CLOB pricing.

Current provider capability notes live in `docs/PROVIDER_CAPABILITIES.md`.
