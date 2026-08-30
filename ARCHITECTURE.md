# Oddsight Architecture

## Current Repository State

The repository currently contains a minimal native iOS SwiftUI app:

- `Oddsight/Oddsight/ContentView.swift`
- `Oddsight/Oddsight/OddsightApp.swift`
- `Oddsight/Oddsight/Assets.xcassets`
- `Oddsight/Products/Oddsight.app`

There is no backend, database, provider integration, domain package, test suite, or documentation yet.

## Architecture Recommendation

Use a modular monolith with background workers, not microservices.

The first production architecture should be:

- Mobile app.
- REST API server.
- PostgreSQL database.
- Background ingestion jobs.
- Background matching jobs.
- Background signal evaluation jobs.
- Shared TypeScript domain packages.

This keeps deployment and debugging simple while still separating business logic from transport, database, and UI.

## Repository Structure

Recommended target structure:

```text
apps/
  mobile/
  api/
workers/
  ingestion/
  matching/
  signals/
packages/
  domain/
  providers/
  database/
  shared/
docs/
```

Because the current repository is a SwiftUI starter app, the owner must decide whether to:

- Keep native SwiftUI for iOS and later build Android separately.
- Replace the current app with React Native and Expo.
- Keep the SwiftUI app as a prototype shell while building the backend first.

Recommendation: choose React Native and Expo before substantial mobile implementation if Android is truly required for the first product phase. Keeping a growing SwiftUI app while planning React Native creates avoidable migration cost.

## Application Boundaries

### Mobile App

Responsibilities:

- Render Discover, Scanner, Market Detail, and Alerts.
- Call REST API.
- Cache recent responses lightly for perceived speed.
- Display data freshness and confidence labels.
- Deep-link to Kalshi and Polymarket.
- Store only non-sensitive local preferences and auth tokens securely.

Non-responsibilities:

- Provider API keys.
- Market matching.
- Signal calculation.
- Alert evaluation.
- Arbitrage calculations that require trusted server-side data.

### API Server

Responsibilities:

- Serve mobile workflows.
- Enforce auth and entitlements.
- Read normalized markets, matches, signals, and alerts.
- Validate alert definitions.
- Expose scanner and detail endpoints.
- Apply rate limits.

Non-responsibilities:

- Long-running ingestion loops.
- Heavy AI matching calls in request/response paths.
- Provider polling directly from mobile requests.

### Workers

Responsibilities:

- Poll provider APIs.
- Normalize provider data.
- Store snapshots.
- Generate match candidates.
- Run deterministic and AI-assisted match assessment.
- Evaluate signal rules.
- Evaluate alerts.

Workers can live in the same codebase and deployment image initially. They should be separate processes or scheduled jobs, not separate services.

## Provider Architecture

Define a provider interface in `packages/providers`.

Conceptual TypeScript shape:

```ts
interface PredictionMarketProvider {
  readonly providerCode: ProviderCode;
  listActiveMarkets(cursor?: string): Promise<ProviderPage<ProviderMarket>>;
  getMarket(providerMarketId: string): Promise<ProviderMarketDetail>;
  getOrderBook?(providerMarketId: string): Promise<ProviderOrderBook>;
}
```

Provider adapters should:

- Hide provider-specific API shapes.
- Preserve provider IDs.
- Preserve raw provider timestamps.
- Return explicit capability metadata.
- Mark unavailable data as unavailable, not zero.

## Database

Use PostgreSQL with Prisma for the initial backend.

PostgreSQL is appropriate because Oddsight needs:

- Relational entities and indexes.
- JSONB for provider-specific metadata and match reasoning.
- Time-series-like snapshots without introducing a second database early.
- Full-text search and trigram indexes for candidate generation.

Do not add a dedicated time-series database until snapshot volume proves PostgreSQL is inadequate.

## API

Use REST initially.

Reasons:

- Mobile workflows are straightforward.
- Caching and observability are simple.
- Endpoint contracts are easy to test.
- Avoids early GraphQL schema complexity.

Version endpoints under `/v1`.

## Background Jobs

Initial jobs:

- `ingest:kalshi:markets`
- `ingest:polymarket:markets`
- `snapshot:market-prices`
- `match:generate-candidates`
- `match:assess-candidates`
- `signals:evaluate`
- `alerts:evaluate`

Use a simple job queue such as BullMQ with Redis only when needed. For local development and early MVP, scheduled worker loops may be enough. Add a queue when retries, backoff, concurrency controls, and delayed jobs become painful.

## Data Flow

1. Ingestion worker fetches provider markets.
2. Provider adapter maps raw data to provider DTOs.
3. Normalization layer writes Events, Markets, Contracts, and Snapshots.
4. Matching worker creates candidate pairs.
5. Match assessment stores confidence, reasoning, and status.
6. Signal worker evaluates snapshots, matches, and order books.
7. API serves ranked scanner results.
8. Mobile app displays signals and links to source platforms.

## Mobile Architecture

If using React Native and Expo:

- TypeScript strict mode.
- API client generated or typed from shared contracts.
- Feature directories: `discover`, `scanner`, `markets`, `alerts`, `settings`.
- State management should start with TanStack Query for server state.
- Avoid business calculations in components.
- Keep visual design dark-mode first, professional, compact, and data dense.

If keeping SwiftUI:

- Use Swift concurrency.
- Keep API models separate from view models.
- Use observable state per screen.
- Do not embed scanner calculations in views.

## Deployment Strategy

Initial production-leaning setup:

- API and workers deployed as separate processes from the same container image.
- PostgreSQL managed database.
- Redis only if a queue is introduced.
- Environment variables managed outside source control.
- Structured logs shipped to a hosted log system.
- API deployed behind HTTPS with rate limiting.

Avoid Kubernetes for MVP unless the team already operates it.

## Observability

Track:

- Provider request latency, errors, and rate limits.
- Ingestion lag.
- Snapshot freshness.
- Match candidate counts.
- AI matching call volume and cost.
- Signal counts by type and severity.
- Alert evaluation latency.
- API latency by endpoint.

## Testing Strategy

Required early tests:

- Unit tests for probability calculations.
- Unit tests for bid/ask spread and arbitrage math.
- Unit tests for normalization.
- Unit tests for signal thresholds.
- Unit tests for match confidence scoring.
- Integration tests for provider adapters using recorded fixtures.
- API contract tests for mobile endpoints.

## Architecture Risks

- Starting with SwiftUI conflicts with the stated React Native and Android goal.
- Real-time scanner expectations can outpace provider API reliability.
- AI-assisted matching can become expensive if used before deterministic filtering.
- Alert delivery should not be built before scanner signal quality is measured.
