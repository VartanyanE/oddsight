# Oddsight Product Plan

## Target User

Oddsight is for active prediction-market traders who already browse Kalshi, Polymarket, or similar venues and want a faster way to find markets worth investigating. The initial user is not a casual forecaster. They understand implied probability, bid/ask spread, liquidity, expiration, and settlement risk.

Secondary users include market researchers, journalists, analysts, and funds using prediction markets as an alternative data source. These users matter later, but the MVP should be built for traders first because they have the clearest willingness to pay for timely signals.

## Core Problem

Prediction-market opportunities are fragmented across platforms. Traders must manually browse different interfaces, interpret different market wording, compare prices, check liquidity, and judge whether markets are truly equivalent. This is slow, error-prone, and easy to miss during fast market movement.

The hardest product problem is not listing markets. The hard part is deciding which markets deserve attention right now, while being honest about uncertainty, stale data, non-equivalent settlement rules, and non-executable prices.

## Value Proposition

Oddsight answers: "What is happening across prediction markets right now that is worth my attention?"

The MVP should provide:

- A unified view of active Kalshi and Polymarket markets.
- Ranked scanner results for discrepancies, movement, and unusual activity.
- Market detail pages that separate last price, midpoint, bid, ask, and executable prices where available.
- Matched cross-platform markets with confidence and reasoning.
- Direct links to original market pages.
- Alerts once the underlying scanner logic is reliable.

Oddsight must position itself as prediction-market intelligence, not a trading venue, broker, or source of guaranteed profit.

## MVP Scope

The MVP is Oddsight Scanner.

In scope:

- Active market ingestion from Kalshi and Polymarket.
- Provider adapters behind a common interface.
- Normalized internal market, contract, snapshot, and signal models.
- Basic market browsing.
- Market detail for normalized markets.
- Automated candidate matching with conservative confidence labels.
- Cross-market discrepancy detection.
- Potential arbitrage detection only when prices and settlement assumptions support that label.
- Probability movement signals based on stored snapshots.
- Volume/activity signals where provider data is available.
- A scanner UI ranked by actionable attention value.
- Saved alert definitions, even if push delivery comes later.

Out of scope for MVP:

- Wallets, deposits, withdrawals, custody, or execution.
- Social feeds, chat, copy trading, public profiles, or community features.
- Portfolio accounting.
- Complex AI forecasting.
- Guaranteed arbitrage claims.
- Subscription payments.
- Every possible prediction-market platform.
- Enterprise analytics.

## User Journeys

### Discover What Matters Now

1. User opens the app.
2. Discover shows the most noteworthy markets and signals across platforms.
3. User taps a market or signal.
4. User sees why Oddsight surfaced it and whether the data is fresh.
5. User opens the original platform link to investigate or trade externally.

### Use the Scanner

1. User opens Scanner.
2. Scanner shows ranked signals: discrepancies, potential arbitrage, movement, volume spikes, and cross-platform divergence.
3. User filters by signal type, platform, category, expiration, volume, liquidity, discrepancy size, and match confidence.
4. User opens a scanner result to inspect market details, data freshness, settlement notes, and supporting calculations.

### Compare Matched Markets

1. User opens a matched market.
2. Oddsight displays both platform contracts together.
3. User sees normalized wording, prices, bid/ask, liquidity, expiration, and match confidence.
4. User reviews match reasoning before treating the comparison as meaningful.

### Create an Alert

1. User opens a market, match, or scanner filter.
2. User creates an alert such as discrepancy above 6 percentage points or probability move above 8 percentage points in one hour.
3. Backend stores the alert definition.
4. Initial MVP can surface in-app alert state; push notifications are a later milestone.

## Screens

### Discover

Purpose: summarize what is happening now.

Initial sections:

- Top signals.
- Biggest probability increases.
- Biggest probability decreases.
- Highest-volume markets.
- New active markets.
- Cross-platform discrepancies.

### Scanner

Purpose: professional signal workbench.

Initial controls:

- Signal type.
- Platform.
- Category.
- Expiration window.
- Minimum volume.
- Minimum liquidity.
- Minimum discrepancy.
- Match confidence.

Initial rows/cards:

- Signal type.
- Market title.
- Platform or matched platforms.
- Key metric.
- Severity.
- Confidence.
- Freshness.
- Link to detail.

### Market Detail

Purpose: explain one market and its signals.

Initial sections:

- Market title and normalized question.
- Platform, category, expiration, status.
- Price data with clear labels.
- Volume and liquidity.
- Recent probability movement.
- Resolution summary.
- Related matched markets.
- Oddsight signals.
- Original platform link.

### Alerts

Purpose: manage saved alert definitions.

Initial sections:

- Active alerts.
- Trigger condition.
- Scope.
- Last evaluated time.
- Status.
- Delivery method placeholder.

## Feature Principles

- Favor fewer, stronger scanner signals over many weak feeds.
- Label stale data clearly.
- Never call last-traded price executable.
- Use "Potential Arbitrage" unless economic equivalence and executability are verified.
- Show match confidence and match reasoning near every cross-market comparison.
- Prefer "unknown" over fabricated precision.
- Avoid casino language and visual patterns.

## Monetization Assumptions

Do not implement payments in the MVP.

Design for future entitlements:

- Free: market browsing, Discover, limited Scanner.
- Pro: full Scanner, advanced filters, alerts, enhanced comparisons.
- Elite: fastest alerts, deeper arbitrage scanner, advanced unusual activity.

Pricing should remain configuration, not hard-coded domain logic.

## Success Metrics

MVP product metrics:

- Weekly active scanner users.
- Scanner result open rate.
- Original platform outbound link clicks.
- Alert creation rate.
- Return frequency among active traders.
- Median scanner response time.
- Percentage of signals with fresh data.
- False-positive rate for matched markets.
- User-reported useful signal rate.

Quality metrics:

- Provider ingestion success rate.
- Snapshot freshness by platform.
- Match review disagreement rate.
- Signal calculation test coverage.
- Number of scanner signals backed by executable bid/ask data.

## Weak Assumptions To Challenge

- API availability may not support all desired data. Large trades, detailed order books, and historical volume may be missing, delayed, or rate-limited.
- Cross-platform arbitrage may be rare after fees, spread, withdrawal friction, and settlement differences.
- Market matching can create dangerous false positives if title similarity is overweighted.
- Real-time alerts are operationally expensive and should wait until data quality is proven.
- A native Swift app exists today, but the preferred long-term stack says React Native and Expo. This must be resolved before building significant mobile UI.
