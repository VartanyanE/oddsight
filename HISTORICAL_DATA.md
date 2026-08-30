# Historical Data Strategy

## Why History Matters

Historical data is necessary for charts, baselines, unusual activity detection, signal backtesting, and long-term defensibility. Oddsight should build its own cleaned prediction-market history, but it should avoid storing unlimited raw provider responses without a clear use.

## Storage Principles

- Store normalized snapshots frequently enough for scanner signals.
- Store raw provider metadata selectively for debugging and reprocessing.
- Roll up old snapshots into aggregates.
- Preserve data freshness and provider timestamps.
- Track data quality so backtests can exclude bad periods.

## Snapshot Types

## Market Snapshots

Store frequently for active markets:

- Implied probability.
- Last trade price.
- Midpoint.
- Best bid.
- Best ask.
- Volume.
- Volume windows if available.
- Liquidity.
- Open interest if available.
- Provider observed timestamp.
- Ingestion timestamp.
- Data quality.

## Contract Snapshots

Store when contract-level pricing is distinct:

- YES bid/ask.
- NO bid/ask.
- Contract volume.
- Contract open interest.
- Bid/ask size.

## Order Book Snapshots

Store selectively:

- Top-of-book for active scanner markets.
- Deeper book for matched markets and potential arbitrage candidates.
- Shorter retention than market snapshots unless a clear use emerges.

## Raw Data Retention

Do not store every raw API response forever.

Recommended approach:

- Store current raw provider metadata on ProviderMarket.
- Store raw snapshots only for parser failures, data anomalies, and sampled debugging.
- Store recorded fixtures for provider adapter tests.
- Store AI match assessment inputs and outputs when used.

## Snapshot Frequency

Initial defaults:

- High-priority active markets: every 1-2 minutes.
- Normal active markets: every 5 minutes.
- Low-volume active markets: every 15 minutes.
- Closed/resolved markets: stop frequent snapshots, retain final state.

Frequency should adapt to:

- Market volume.
- Open interest or liquidity.
- Expiration proximity.
- Recent movement.
- Existing alerts.
- Provider rate limits.

## Aggregation

Roll up snapshots into:

- 1-minute buckets for recent high-resolution charts.
- 5-minute buckets.
- 1-hour buckets.
- 1-day buckets.

Aggregate fields:

- Open/high/low/close probability.
- Open/high/low/close bid and ask when available.
- Total volume.
- Liquidity min/max/close.
- Snapshot count.
- Data quality summary.

## Retention

Initial retention recommendation:

- Raw order book snapshots: 7-14 days.
- Market and contract snapshots: 90 days at native frequency.
- 1-minute aggregates: 90 days.
- 5-minute aggregates: 1 year.
- Hourly aggregates: indefinite or multi-year.
- Daily aggregates: indefinite.

Adjust once actual data volume is measured.

## Baseline Calculations

Baselines power unusual activity signals.

Initial baselines:

- Rolling median hourly volume by market.
- Rolling median probability volatility by market.
- Category-level fallback for new markets.
- Time-to-expiration adjusted baseline.

Later baselines:

- Time-of-day and day-of-week adjustments.
- Event-type-specific baselines.
- Provider-specific liquidity baselines.
- News-window anomaly handling.

## Backtesting

Store enough data to answer:

- Did signals precede meaningful price movement?
- Which signal thresholds generated too many false positives?
- Which categories produce useful discrepancies?
- How often did potential arbitrage remain executable after fees?
- Which provider fields were stale or unreliable?

Backtests should use point-in-time data only. Do not allow future snapshots or revised data to leak into historical signal evaluation.

## Data Growth Controls

Controls:

- Adaptive polling.
- Snapshot deduplication when values have not changed.
- Partition large snapshot tables by time.
- Archive cold aggregates.
- Short retention for deep order books.
- Index only query-critical columns.

PostgreSQL should be sufficient for MVP if retention and indexes are disciplined.

## Data Quality

Each snapshot should track:

- Provider observed time.
- Oddsight ingestion time.
- Freshness.
- Missing fields.
- Provider error state.
- Normalization version.

UI and signal confidence should reflect data quality.

## Historical Data Risks

- Provider definitions can change over time.
- Volume fields may be cumulative, rolling, or delayed.
- Excessive polling can hit rate limits.
- Deep order book history can grow quickly.
- Bad historical baselines can produce noisy alerts.
