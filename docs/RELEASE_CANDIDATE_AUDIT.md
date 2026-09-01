# SOUL V1 release-candidate audit

This audit records backend checks completed after the sixteen planned V1 phases. It is a code-readiness record, not a production deployment approval.

## Identity and access

- Public APIs return consistent request identifiers and error envelopes.
- Authenticated routes require an active account unless deletion cancellation explicitly requires access for a scheduled account.
- Administration routes require an authenticated moderator or super-admin role.
- Provider secrets, password hashes, internal database IDs and media provider asset IDs are not returned to clients.

## Discovery and interaction eligibility

- Discovery requires a live viewer profile and saved preferences.
- Candidates must be live, active, discoverable, unblocked and within configured age, gender and country filters.
- Previously liked or passed profiles are excluded from subsequent candidate pages.
- Direct decision requests cannot bypass live-profile or target discoverability requirements.
- Match listing and messaging require both participants to remain active.

## Safety and privacy

- Blocking closes an active match and prevents discovery, decisions and messaging in both directions.
- Reports, verification cases, appeals and moderation decisions have authenticated ownership or role checks.
- Data exports use private storage, expire after seven days and are owner-downloadable only.
- Account deletion has an explicit confirmation phrase and a seven-day cancellation window.
- Expired exports and stale OTP records are removed by scheduled maintenance.

## Scale and operations

- High-volume feeds use cursor pagination.
- Discovery has a composite candidate lookup index and decision/block filters use indexed keys.
- Readiness checks cover database and cache dependencies.
- API responses include security headers, request correlation and server timing.
- CI builds the React admin, runs dependency audits and executes the Laravel test suite.

## External launch gates

- Configure production MySQL, Redis, private export storage and queue workers.
- Configure Cloudinary, email, Google and Apple credentials in the secret manager.
- Run migrations and smoke tests in staging before production rollout.
- Verify backups, restore procedure, alerting and rollback with the operations owner.
