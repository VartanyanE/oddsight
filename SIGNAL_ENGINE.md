# Oddsight Signal Engine

## Principles

- Signals must be explainable.
- Calculations must be server-side and unit-tested.
- Separate signal severity from signal confidence.
- Separate theoretical opportunity from executable opportunity.
- Provider data capability must be verified before enabling a signal.
- Never infer missing bid/ask or order-book data from last-traded prices.

## Signal Types

Initial signal types:

- `cross_market_discrepancy`
- `potential_arbitrage`
- `probability_move`
- `volume_spike`
- `volume_acceleration`
- `liquidity_change`
- `large_trade`
- `new_matched_market`

Some may remain disabled until provider data supports them.

## Cross-Market Discrepancy

Definition: difference between comparable implied probabilities for matched contracts.

Formula:

```text
discrepancy = abs(probabilityA - probabilityB)
```

Preferred inputs:

- Executable midpoint or best bid/ask-derived probability if available.
- Midpoint if order book is available but execution is not being simulated.
- Last-traded price only as a weaker signal.

Required fields:

- Matched markets.
- Match confidence.
- Comparable outcome polarity.
- Recent snapshots.

Confidence inputs:

- Match confidence.
- Snapshot freshness.
- Price field quality.
- Data completeness.

## Potential Arbitrage

Definition: possible positive payout spread across equivalent YES/NO positions.

Binary example:

```text
combinedCost = yesAskOnPlatformA + noAskOnPlatformB
grossProfit = 1.00 - combinedCost
grossReturn = grossProfit / combinedCost
```

Signal condition:

```text
combinedCost < 1.00
```

But the signal should be labeled potential, not guaranteed, unless:

- Settlement rules are verified equivalent.
- Prices are executable asks.
- Available size is known.
- Fees are included.
- Contract payout units are compatible.
- Data is fresh.

Future adjusted formula:

```text
netProfit = payout - combinedCost - estimatedFees - estimatedSlippage - transferCosts
netReturn = netProfit / combinedCost
```

Severity can depend on:

- Gross or net return.
- Available liquidity.
- Match status.
- Data freshness.

## Probability Move

Definition: a market's implied probability changes materially over a time window.

Formula:

```text
move = currentProbability - previousProbability
absoluteMove = abs(move)
```

Windows:

- 15 minutes.
- 1 hour.
- 24 hours.

Initial threshold examples:

- Medium: 5 percentage points in 1 hour.
- High: 10 percentage points in 1 hour.
- Critical: 15 percentage points in 1 hour.

These thresholds should be configuration and should be tuned with historical data.

## Volume Spike

Definition: current volume rate is materially above baseline.

Formula:

```text
volumeMultiple = currentWindowVolume / baselineWindowVolume
```

Baseline options:

- Same market rolling median.
- Category-level baseline for new markets.
- Time-of-day adjusted baseline once enough data exists.

Minimum conditions:

- Baseline must be non-trivial.
- Current volume must exceed an absolute floor.

Example thresholds:

- Medium: 3x baseline.
- High: 8x baseline.
- Critical: 15x baseline.

Do not enable until provider volume fields and update cadence are verified.

## Volume Acceleration

Definition: rate of volume increase is rising quickly.

Formula:

```text
acceleration = currentVolumeRate / previousVolumeRate
```

This can detect activity before total volume becomes large. It is noisy and should require minimum liquidity and freshness.

## Liquidity Change

Definition: liquidity or order-book depth changes quickly.

Formula:

```text
liquidityChange = currentLiquidity - previousLiquidity
liquidityChangePercent = liquidityChange / previousLiquidity
```

Inputs:

- Provider liquidity field, if meaningful.
- Order-book depth, if available.

Risks:

- Providers define liquidity differently.
- Order-book snapshots may be sparse.
- Market maker inventory changes can look like meaningful signal but may be mechanical.

## Large Trade

Definition: trade size materially exceeds baseline trade size.

Formula:

```text
tradeMultiple = tradeSize / baselineTradeSize
```

This signal requires trade-level data. If provider APIs do not expose trades reliably, keep this disabled.

## Severity

Severity describes magnitude and urgency.

Suggested levels:

- `low`
- `medium`
- `high`
- `critical`

Severity inputs:

- Metric magnitude.
- Liquidity.
- Recency.
- Expiration proximity.
- Market volume.

Severity should not imply correctness. A large discrepancy on a possible match can be high severity but low confidence.

## Confidence

Confidence describes trust in the signal.

Inputs:

- Data freshness.
- Provider capability.
- Match confidence.
- Price field type.
- Historical baseline quality.
- Sample size.
- Calculation completeness.

Examples:

- A discrepancy based on verified match and fresh executable bid/ask can be high confidence.
- A discrepancy based on last trade and possible match should be low confidence.

## Ranking

Scanner ranking can start with a transparent weighted sort:

- Signal severity.
- Signal confidence.
- Data freshness.
- Liquidity or volume.
- Match confidence.
- Expiration relevance.

Do not brand this as Oddsight Score until it has evidence and calibration.

## Provider Capability Reality Check

Before enabling each signal, verify for each provider:

- Active market endpoint availability.
- Price fields and semantics.
- Best bid and ask availability.
- Order book depth availability.
- Volume fields and windows.
- Trade-level data availability.
- Liquidity definition.
- Historical data access.
- Rate limits and update cadence.

The MVP can ship with a smaller signal set if data quality is strong.

## Required Tests

Unit tests:

- Probability conversion.
- Discrepancy calculation.
- Bid/ask spread calculation.
- Potential arbitrage gross return.
- Fee-adjusted return.
- Probability move windows.
- Volume spike baseline logic.
- Severity thresholds.
- Confidence caps.

Fixture tests:

- Missing bid/ask.
- Stale snapshot.
- Low-confidence match.
- Different contract polarity.
- Partial data from one provider.

## Signal Risks

- Last-trade data can overstate opportunities.
- Thin markets can create misleading discrepancies.
- Baselines are weak for new markets.
- High volatility around news can make delayed data harmful.
- Too many low-quality alerts will damage trust quickly.
