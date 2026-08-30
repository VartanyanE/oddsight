# Oddsight Decisions Log

## 1. Mobile Stack

Question: Should Oddsight continue with the current SwiftUI app or switch to React Native and Expo?

Options:

- Keep SwiftUI for iOS and build Android later.
- Switch to React Native and Expo now.
- Build backend first while delaying the mobile decision.

Recommendation: switch to React Native and Expo before substantial mobile work if Android is required for the first serious launch.

Current decision: keep SwiftUI for the initial native iOS build. Revisit before committing to Android or broad cross-platform launch work.

Tradeoffs:

- SwiftUI can produce a high-quality iOS app quickly but does not satisfy Android.
- React Native aligns with the stated preferred stack and cross-platform goal but requires replacing the starter app.
- Delaying the decision avoids immediate churn but risks duplicated mobile work.

When decision must be made: before Milestone 1 mobile foundation.

## 2. MVP Provider Scope

Question: Should the MVP include both Kalshi and Polymarket from the first scanner release?

Options:

- Build both immediately.
- Build one provider first, then add the second.
- Build provider capability verification for both, then implement one at a time.

Recommendation: verify capabilities for both, then implement ingestion one provider at a time.

Tradeoffs:

- Both are required for cross-market discrepancy value.
- Implementing both blindly may reveal incompatible or missing data late.
- One-at-a-time ingestion improves reliability and testability.

When decision must be made: Milestone 2.

## 3. Real-Time Expectations

Question: How real-time should Oddsight claim to be?

Options:

- Real-time.
- Near real-time.
- Freshness-labeled market intelligence.

Recommendation: use freshness-labeled market intelligence until provider update cadence and rate limits are proven.

Tradeoffs:

- Real-time is stronger marketing but creates reliability and legal risk.
- Freshness labels build trust and reduce overclaiming.

When decision must be made: before public positioning.

## 4. Potential Arbitrage Label

Question: When can Oddsight label a signal as potential arbitrage?

Options:

- Any crossed implied probabilities.
- Only executable bid/ask plus high-confidence match.
- Only verified settlement equivalence, executable prices, and fee-aware calculations.

Recommendation: for MVP, use "Potential Arbitrage" only with high match confidence and executable bid/ask data. Use stronger labels only after verified settlement equivalence and fee modeling.

Tradeoffs:

- Conservative labels may reduce signal count.
- Loose labels may damage trust and create compliance risk.

When decision must be made: before Signal Engine V1.

## 5. AI Usage In Matching

Question: How much should market matching rely on LLMs?

Options:

- LLM for every comparison.
- Deterministic and embedding filters first, LLM only for selected candidates.
- No LLM in MVP.

Recommendation: deterministic and embedding filters first, LLM only for ambiguous or high-value candidates.

Tradeoffs:

- Full LLM matching is expensive and harder to test.
- No LLM may miss nuanced rule differences.
- Selective LLM use balances cost, quality, and auditability.

When decision must be made: before Market Matching V1.

## 6. Manual Review

Question: Does MVP need manual match review?

Options:

- No review tooling.
- Minimal internal review tools.
- Full admin workflow.

Recommendation: build minimal internal review support in the data model and basic tooling, not a full admin product.

Tradeoffs:

- No review increases false-positive risk.
- Full admin UI delays launch.
- Minimal review provides safety for high-impact matches.

When decision must be made: before high-confidence matching is exposed.

## 7. Alert Delivery

Question: Should push notifications ship with initial alerts?

Options:

- Ship push notifications immediately.
- Ship server-side alert evaluation first, push later.
- Delay alerts entirely.

Recommendation: ship server-side alert evaluation first, then add push notifications.

Tradeoffs:

- Push is valuable but operationally sensitive.
- Alert logic must be trusted before interrupting users.

When decision must be made: before Alerts V1.

## 8. Oddsight Score

Question: Should the MVP show an Oddsight Score?

Options:

- Show a provisional score.
- Hide score until methodology is validated.
- Show component metrics without a score.

Recommendation: show component metrics and ranking, but do not brand an Oddsight Score yet.

Tradeoffs:

- A score is marketable.
- A weak score can look arbitrary and reduce credibility.
- Component metrics are transparent and easier to test.

When decision must be made: before Scanner UI launch.

## 9. Historical Retention

Question: How much raw historical data should Oddsight store?

Options:

- Store every raw provider response forever.
- Store normalized snapshots and selective raw samples.
- Store only latest state.

Recommendation: store normalized snapshots and selective raw samples, then aggregate old data.

Tradeoffs:

- Full raw storage improves reprocessing but increases cost and noise.
- Latest-only storage prevents baselines and backtesting.
- Normalized snapshots support product needs with controlled growth.

When decision must be made: before Snapshot worker.

## 10. Authentication Timing

Question: When should authentication be implemented?

Options:

- From Milestone 1.
- Before alerts.
- After MVP scanner.

Recommendation: implement lightweight production-ready auth before alerts, not necessarily before anonymous market browsing.

Tradeoffs:

- Early auth adds setup time.
- Alerts require user identity.
- Anonymous browsing can speed scanner validation.

When decision must be made: before Alerts V1.

## 11. Subscription Provider

Question: Should RevenueCat or another subscription provider be selected now?

Options:

- RevenueCat.
- Native App Store and Play Billing directly.
- Defer subscription provider.

Recommendation: defer implementation but design entitlement tables now. Revisit provider choice after scanner value is proven.

Tradeoffs:

- Early subscription work distracts from scanner quality.
- Entitlement architecture is cheap to prepare.

When decision must be made: before paid beta.

## 12. Legal Review

Question: When is legal review required?

Options:

- Before any public launch.
- Before subscriptions.
- Before alerts and arbitrage language.

Recommendation: get legal review before public beta if Scanner includes potential arbitrage, alerts, or personalized saved conditions.

Tradeoffs:

- Legal review can slow launch.
- Compliance mistakes are expensive and can force rework.

When decision must be made: before public beta.
