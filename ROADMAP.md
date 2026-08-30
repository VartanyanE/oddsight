# Oddsight Roadmap

## Milestone 0: Architecture Approval

Objective: agree on product scope, stack, and architecture before implementation.

Functionality:

- Planning documents reviewed.
- MVP scope approved.
- Mobile stack decision made.

Backend work:

- None.

Database work:

- None.

Mobile work:

- None beyond current starter app.

Tests:

- None.

Dependencies:

- Owner approval.

Definition of done:

- `PRODUCT.md`, `ARCHITECTURE.md`, `DATA_MODEL.md`, `API_DESIGN.md`, `MARKET_MATCHING.md`, `SIGNAL_ENGINE.md`, `HISTORICAL_DATA.md`, `SECURITY.md`, `ROADMAP.md`, and `DECISIONS.md` approved or amended.

## Milestone 1: Repository And Platform Foundation

Objective: create the runnable project foundation.

Functionality:

- Monorepo or chosen app structure.
- API skeleton.
- Mobile app skeleton.
- Shared domain package.
- Local development setup.

Backend work:

- Node.js TypeScript API.
- Health endpoint.
- Structured logging.
- Environment validation.

Database work:

- PostgreSQL connection.
- Prisma setup.
- Initial migrations.

Mobile work:

- App shell with Discover, Scanner, Market, Alerts navigation.
- API client setup.

Tests:

- API health test.
- Domain package test setup.
- Mobile smoke test.

Dependencies:

- Mobile stack decision.

Definition of done:

- One command starts API and mobile locally.
- CI or local test command passes.

## Milestone 2: Provider Capability Verification

Objective: verify actual Kalshi and Polymarket data capabilities before building signals.

Functionality:

- Provider research and recorded sample responses.
- Capability matrix.
- Fixture files for tests.

Backend work:

- Prototype provider calls.
- Capability metadata model.

Database work:

- Provider table and provider market table.

Mobile work:

- None required.

Tests:

- Fixture parsing tests.

Dependencies:

- API access and rate-limit understanding.

Definition of done:

- Documented fields available from each provider: prices, bid/ask, order book, volume, liquidity, trades, timestamps, resolution rules.

## Milestone 3: Kalshi Ingestion

Objective: ingest active Kalshi markets into normalized storage.

Functionality:

- Active market listing.
- Market detail ingestion.
- Basic snapshot storage.

Backend work:

- `KalshiProvider`.
- Normalization pipeline.
- Ingestion worker.

Database work:

- ProviderMarket, Market, Contract, MarketSnapshot.

Mobile work:

- None or developer-only market list.

Tests:

- Adapter fixture tests.
- Normalization tests.
- Ingestion idempotency tests.

Dependencies:

- Milestone 2.

Definition of done:

- Local worker ingests Kalshi active markets repeatedly without duplicates.

## Milestone 4: Polymarket Ingestion

Objective: ingest active Polymarket markets into normalized storage.

Functionality:

- Active market listing.
- Market detail ingestion.
- Basic snapshot storage.

Backend work:

- `PolymarketProvider`.
- Provider-specific normalization.

Database work:

- Same normalized tables used by Kalshi.

Mobile work:

- None or developer-only market list.

Tests:

- Adapter fixture tests.
- Normalization parity tests.

Dependencies:

- Milestones 2 and 3 patterns.

Definition of done:

- Local worker ingests Polymarket active markets repeatedly without duplicates.

## Milestone 5: Unified Market Browser

Objective: make normalized market data visible in the app.

Functionality:

- `GET /v1/markets`.
- `GET /v1/markets/:id`.
- Market list screen.
- Market detail screen.

Backend work:

- Market API endpoints.
- Search and filters.

Database work:

- Query indexes.

Mobile work:

- Discover baseline list.
- Market detail with freshness and source link.

Tests:

- API endpoint tests.
- Mobile rendering smoke tests.

Dependencies:

- Kalshi and Polymarket ingestion.

Definition of done:

- User can browse normalized markets from both providers in a runnable app.

## Milestone 6: Historical Snapshots And Charts

Objective: store enough history for movement signals.

Functionality:

- Snapshot scheduler.
- Historical aggregation.
- Market history endpoint.
- Basic probability chart.

Backend work:

- Snapshot worker.
- Aggregation worker.

Database work:

- Snapshot indexes.
- HistoricalAggregate table.

Mobile work:

- Simple market probability history chart.

Tests:

- Aggregation tests.
- History endpoint tests.

Dependencies:

- Unified market ingestion.

Definition of done:

- Market detail shows recent probability history from stored Oddsight data.

## Milestone 7: Automated Market Matching V1

Objective: produce conservative matched-market candidates.

Functionality:

- Deterministic normalization.
- Structured extraction.
- Candidate generation.
- Confidence labels.
- Match detail API.

Backend work:

- Matching worker.
- Match assessment persistence.
- Admin review placeholder.

Database work:

- MatchedMarket and MatchAssessment.

Mobile work:

- Matched markets shown in market detail.

Tests:

- Match fixture suite.
- False-positive tests.
- Confidence cap tests.

Dependencies:

- Both providers ingested.

Definition of done:

- System creates possible and high-confidence matches with stored reasoning.

## Milestone 8: Cross-Market Comparison

Objective: calculate trustworthy price differences for matched markets.

Functionality:

- Price comparison engine.
- Discrepancy endpoint fields.
- Match detail comparison UI.

Backend work:

- Comparison calculations.
- Price-field quality labels.

Database work:

- Store comparison snapshots if needed.

Mobile work:

- Matched market comparison panel.

Tests:

- Discrepancy tests.
- Bid/ask semantic tests.
- Stale data tests.

Dependencies:

- Matching V1.
- Snapshot data.

Definition of done:

- User can compare equivalent markets with clear data-quality labels.

## Milestone 9: Signal Engine V1

Objective: generate the first useful scanner signals.

Functionality:

- Cross-market discrepancy signal.
- Probability movement signal.
- Volume spike only if verified provider data supports it.
- Signal detail endpoint.

Backend work:

- Signal evaluator.
- Signal ranking logic.

Database work:

- Signal table.

Mobile work:

- Scanner list.
- Signal detail.

Tests:

- Signal formula tests.
- Ranking tests.
- Confidence tests.

Dependencies:

- Historical snapshots.
- Cross-market comparison.

Definition of done:

- Scanner shows ranked, explainable signals from real ingested data.

## Milestone 10: Alerts V1

Objective: allow users to save server-side alert definitions.

Functionality:

- Create, list, update, delete alerts.
- Server-side evaluation.
- In-app triggered state.

Backend work:

- Alert API.
- Alert evaluator.
- Auth required.

Database work:

- User, Alert, AlertTrigger.

Mobile work:

- Alerts screen.
- Create alert flow from Scanner and Market Detail.

Tests:

- Authorization tests.
- Alert condition tests.
- Trigger tests.

Dependencies:

- Signal Engine V1.
- Auth.

Definition of done:

- Authenticated user can create alerts that evaluate server-side.

## Milestone 11: Push Notifications

Objective: deliver timely alerts outside the app.

Functionality:

- Device token registration.
- Push delivery.
- Notification preferences.

Backend work:

- Push service integration.
- Delivery retries.

Database work:

- DeviceToken table or equivalent.

Mobile work:

- Permission flow.
- Notification handling.

Tests:

- Push registration tests.
- Delivery status tests.

Dependencies:

- Alerts V1.

Definition of done:

- User receives push notifications for triggered alerts.

## Milestone 12: Entitlements And Subscription Readiness

Objective: prepare monetization without hard-coding pricing.

Functionality:

- Feature gates.
- Tier limits.
- Subscription provider integration later.

Backend work:

- Entitlement checks.
- Plan configuration.

Database work:

- Entitlement records.

Mobile work:

- Upgrade prompts and gated states.

Tests:

- Entitlement enforcement tests.

Dependencies:

- Clear pricing and packaging decision.

Definition of done:

- Backend can enforce scanner and alert limits by tier.

## Roadmap Priority

When scope conflicts arise, prioritize:

1. Scanner quality.
2. Data reliability.
3. Match accuracy.
4. Mobile speed.
5. Alert usefulness.
6. Monetization.
