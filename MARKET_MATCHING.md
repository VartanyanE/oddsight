# Market Matching Strategy

## Why Matching Is Core

Market matching is a potential Oddsight moat. Kalshi and Polymarket may describe similar events differently, and superficial title similarity can create false positives. A false match can make a harmless price difference look like an opportunity, or worse, make a non-equivalent settlement condition look like potential arbitrage.

The system must be conservative. A low-confidence match is useful for research but should not trigger high-priority arbitrage alerts.

## Matching Pipeline

Use staged matching:

1. Deterministic normalization.
2. Structured field extraction.
3. Candidate generation.
4. Semantic similarity.
5. Deterministic settlement comparison.
6. AI-assisted contract comparison for uncertain or high-value candidates.
7. Confidence scoring.
8. Human review and override.

LLM calls should not run for every possible market pair.

## Stage 1: Deterministic Normalization

Normalize text and basic fields:

- Lowercase.
- Remove punctuation noise.
- Normalize dates.
- Normalize common aliases such as BTC and Bitcoin.
- Normalize currency symbols and numeric thresholds.
- Normalize percentages.
- Normalize timezones where explicit.
- Strip provider boilerplate where safe.

Output:

- `normalizedQuestion`
- `normalizedRules`
- normalized dates
- extracted known aliases
- tokenized searchable text

This stage should be deterministic and fully testable.

## Stage 2: Structured Field Extraction

Extract structured market components:

- Subject or entity.
- Event/action.
- Outcome direction.
- Numeric threshold.
- Measurement period.
- Expiration date.
- Settlement timestamp.
- Geographic scope.
- Resolution source.
- Resolution criteria.
- Contract polarity.

Examples:

- Subject: Bitcoin.
- Metric: USD spot price.
- Threshold: 150000.
- Operator: greater than.
- Timestamp: 2026-12-31 end of day.
- Resolution source: specified exchange or oracle, if available.

Use deterministic parsers for dates, numbers, currencies, common operators, and known entities. Use AI extraction only when deterministic extraction cannot confidently structure the contract text.

## Stage 3: Candidate Generation

Avoid all-pairs comparison.

Generate candidates using:

- Same or adjacent category.
- Overlapping expiration windows.
- Shared entities or aliases.
- Similar extracted thresholds.
- Full-text search.
- Trigram similarity.
- Embedding similarity.

Candidate generation should favor recall while keeping candidate volume bounded.

Initial filters:

- Active markets only.
- Expiration within a configurable window.
- Same broad category unless entity similarity is strong.
- Similar outcome type.

## Stage 4: Semantic Similarity

Use embeddings or a lightweight semantic model to compare:

- Question text.
- Rules text.
- Extracted event description.
- Outcome wording.

Semantic similarity is a feature, not a final decision. It should never override clear settlement mismatch.

## Stage 5: Settlement-Rule Comparison

Compare structured settlement fields:

- Resolution date.
- Settlement timestamp.
- Timezone.
- Resolution source.
- Measurement period.
- Numeric threshold.
- Operator.
- YES/NO meaning.
- Edge cases.
- Cancellation rules.

This is the main false-positive prevention layer.

Examples of non-equivalence:

- One contract settles on intraday high, another on closing price.
- One uses Coinbase BTC price, another uses Binance.
- One resolves at 11:59 PM ET, another at UTC midnight.
- One asks whether an event happens by a date, another asks whether it happens on a date.
- One contract includes official revisions and another does not.

## Stage 6: AI-Assisted Comparison

Use LLMs only for candidates that pass deterministic filters and have enough value to justify cost.

Good AI use cases:

- Compare long resolution rules.
- Extract edge cases from dense text.
- Explain why two markets differ.
- Produce structured reasoning for human review.

Bad AI use cases:

- Brute-force all market pairs.
- Replacing deterministic date or number parsing.
- Making final verified-match decisions without persisted evidence.

AI output should be schema-constrained:

```json
{
  "sameEconomicEvent": true,
  "outcomeEquivalent": true,
  "settlementEquivalent": false,
  "differences": ["Different resolution timestamp"],
  "confidence": 0.78,
  "recommendedStatus": "possible"
}
```

## Confidence Scoring

Confidence should combine weighted components:

- Event similarity.
- Subject similarity.
- Outcome equivalence.
- Threshold equivalence.
- Date and period similarity.
- Resolution source similarity.
- Settlement timing similarity.
- Rules compatibility.
- Data completeness.

Suggested labels:

- `verified`: reviewed or deterministic equivalence with complete rules.
- `high_confidence`: strong automated confidence, no known material mismatch.
- `possible`: similar, but missing or uncertain settlement fields.
- `needs_review`: high value or ambiguous.
- `rejected`: known mismatch.

Do not show a precise confidence percentage unless the underlying model is calibrated. Early UI can show labels plus component evidence.

## False-Positive Prevention

Rules:

- If outcome polarity is ambiguous, do not classify as high confidence.
- If numeric thresholds differ materially, reject or mark possible.
- If settlement source differs and price-sensitive, do not classify as high confidence.
- If timestamp/timezone differs and could affect outcome, do not classify as verified.
- If one market lacks resolution rules, cap confidence.
- If only titles match, cap confidence aggressively.

## Human Review

Build for manual override early, even if admin UI is basic.

Human review can:

- Verify match.
- Reject match.
- Add notes.
- Correct structured fields.
- Lock a match status.

Reviewed decisions should feed future test fixtures and matching rules.

## Caching

Cache:

- Normalized text.
- Extracted fields.
- Embeddings.
- Candidate lists.
- AI assessments.

Invalidate when:

- Provider rules change.
- Market title or description changes.
- Extraction version changes.
- Matching algorithm version changes.

## AI Cost Controls

- Deterministic filters before AI.
- Batch embedding generation.
- Reuse assessments.
- Only call LLM for high-likelihood or high-impact candidates.
- Cap calls per provider ingestion cycle.
- Track `modelUsed` and `aiCostCents`.
- Prefer smaller models for extraction and larger models only for ambiguous rules comparison.

## Testing Strategy

Test sets:

- Obvious matches.
- Obvious non-matches.
- Same title but different settlement rules.
- Different title but same economic event.
- Polarity inversions.
- Threshold mismatches.
- Date and timezone edge cases.
- Missing rules.

Metrics:

- Candidate recall.
- False-positive rate.
- High-confidence precision.
- Human reviewer disagreement rate.
- AI cost per accepted match.

## MVP Matching Scope

MVP should start with:

- Binary YES/NO markets.
- Categories with clearer structured events, such as economics, crypto, politics, and weather.
- Conservative confidence thresholds.
- Manual review for any signal claiming potential arbitrage.

Do not attempt broad universal matching across every category before the scanner proves value.

## Current Native App V1

The current SwiftUI app includes a deterministic in-app matcher for live Kalshi and Polymarket markets. It:

- Compares only Kalshi-to-Polymarket market pairs.
- Requires compatible categories.
- Normalizes titles and questions into comparable terms.
- Applies a small alias map for common terms such as BTC/Bitcoin and Fed/FOMC.
- Scores token overlap, containment, and expiration text overlap.
- Caps automatic confidence at 92%.
- Produces `High Confidence`, `Possible Match`, and `Needs Review` labels.
- Generates live discrepancy and theoretical potential arbitrage signals from matched candidates.
- Surfaces high-enough match candidates as `New Matched Market` scanner signals even when no discrepancy threshold is met.
- Stores and displays a structured match assessment with event similarity, expiration similarity, shared terms, reasons, risks, and generator name.

This V1 matcher does not verify settlement equivalence, resolution source equivalence, timezone equivalence, or contract edge cases. It must not be treated as a verified arbitrage engine.
