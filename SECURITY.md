# Oddsight Security Plan

## Principles

- Do not put private provider API keys in mobile clients.
- Treat all external API data as untrusted.
- Keep trading, custody, deposits, and withdrawals out of scope.
- Use least-privilege credentials.
- Log operational context without leaking secrets or user tokens.
- Build entitlement checks server-side.

## Authentication

Initial options:

- Hosted auth provider.
- Custom email/password with secure password handling.
- Apple/Google sign-in for mobile.

Recommendation: use a hosted auth provider or well-supported auth library for MVP. Authentication is not Oddsight's differentiator.

Requirements:

- Short-lived access tokens.
- Refresh token rotation where applicable.
- Secure mobile token storage.
- Server-side session invalidation.
- Rate limiting on auth endpoints.

## Authorization

Access control:

- Users can only manage their own alerts.
- Entitlements gate advanced scanner filters and alert limits.
- Admin review tools require explicit admin roles.
- Internal ingestion and worker endpoints require service credentials.

Do not trust client-provided entitlement tier.

## API Security

Controls:

- HTTPS only.
- Rate limiting by IP and user.
- Request validation with schema validation.
- Centralized error handling.
- CORS restricted to known clients where applicable.
- Pagination limits.
- Audit logging for alert and admin changes.

Avoid returning stack traces or provider secrets.

## Secret Management

Secrets:

- Provider API keys.
- Database URL.
- Auth signing keys.
- Push notification credentials.
- AI provider keys.
- Payment provider keys when added.

Rules:

- Store in environment or managed secret store.
- Never commit `.env` files with real secrets.
- Use separate development, staging, and production credentials.
- Rotate secrets after exposure or staff changes.

## External API Safety

Provider responses can be malformed or hostile.

Validate:

- Types.
- Required fields.
- Numeric ranges.
- URLs.
- Timestamps.
- Market status.

Handle:

- Rate limits.
- Retries with exponential backoff.
- Circuit breakers for provider outages.
- Schema changes.
- Duplicate markets.
- Stale data.

## Database Security

Controls:

- Managed PostgreSQL with encryption at rest.
- TLS connections.
- Least-privilege app user.
- Separate migration/admin role.
- Regular backups.
- Tested restore process.
- No direct database access from mobile.

Data considerations:

- Market data is mostly public.
- User alerts, emails, device tokens, and usage behavior are sensitive.

## Mobile Security

Controls:

- Store auth tokens in secure storage.
- Do not embed private provider credentials.
- Use certificate validation through platform defaults.
- Avoid logging tokens or sensitive user data.
- Keep deep links constrained to trusted provider URLs.

## Logging

Log:

- Request IDs.
- Provider errors.
- Ingestion lag.
- Signal calculation failures.
- Alert evaluation outcomes.
- Admin match review changes.

Do not log:

- Access tokens.
- Refresh tokens.
- Provider secrets.
- Full auth headers.
- Push tokens except hashed identifiers.

## Push Notifications

When added:

- Store device tokens securely.
- Let users disable notifications.
- Avoid sensitive content in notification bodies by default.
- Validate provider webhooks if used.

## Compliance And Positioning

Oddsight should avoid acting like:

- Broker.
- Exchange.
- Investment adviser.
- Custodian.
- Gambling operator.

Product language should say:

- Intelligence.
- Analytics.
- Research.
- Market data.
- Potential discrepancy.

Avoid:

- Guaranteed profit.
- Guaranteed arbitrage.
- Sure win.
- Risk-free.

Legal review is required before subscriptions, personalized recommendations, or any feature that looks like trade advice.

## Abuse Risks

Potential abuse:

- Scraping Oddsight data.
- Alert spam.
- Credential stuffing.
- Provider API quota exhaustion.
- Automated account creation.

Controls:

- Rate limits.
- Bot protection on auth.
- Alert count limits by entitlement.
- Provider request quotas.
- Monitoring and anomaly detection.

## Security Milestones

Before public beta:

- Auth implemented.
- Alert authorization tested.
- Secret management in place.
- API validation in place.
- Provider keys server-side only.
- Basic rate limiting.
- Logging redaction.
- Backup and restore tested.
