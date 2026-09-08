# Legal consent and account lifecycle

This guide keeps the Flutter consent flow simple. Laravel owns current document versions and acceptance evidence.

## Documents and commitments

Users accept the current Terms, Privacy Policy, Community Guidelines and one versioned community commitment. The commitment screen shows five neutral promises returned as translation keys: respect everyone, be honest about identity and marital status, avoid harassment/scams/inappropriate behaviour, follow Community Guidelines, and accept Terms/Privacy.

SOUL records document type/version, acceptance time, route used, locale, IP address and a one-way hash of device context. Flutter never receives the IP or device hash.

## Flutter flow

1. Read `legal` from bootstrap. For a signed-in user, `requires_acceptance` is authoritative.
2. Show the localized commitment list and links/content for the current legal documents.
3. Submit every current version to `POST /legal/consent`; partial or stale versions return validation errors.
4. On success, continue. Retrying the same acceptance is safe and does not create duplicate evidence.
5. Check again after login/app update. A future version change makes only that current document unaccepted.

Profile submission also requires the same four current acceptances. It records them with `accepted_via: onboarding`. A live member can re-consent from settings without repeating onboarding.

## Account lifecycle

Profile states remain Draft → Submitted → Automated checks → Live, with explicit correction/pause/rejection states. Account deletion immediately hides the member, revokes access and stays recoverable for 30 days before permanent queued deletion. Safety appeal, privacy and deletion controls cannot be paywalled.
