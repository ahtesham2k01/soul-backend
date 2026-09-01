# SOUL V1 production readiness

This runbook defines the operational requirements for the Laravel API and custom React administration application. It does not authorize or perform a production deployment.

## Required infrastructure

- PHP 8.3+, MySQL 8+, Redis, HTTPS and a supported web server
- A durable private filesystem for generated user data exports
- At least one queue worker and the Laravel scheduler running every minute
- Cloudinary, transactional email, Google and Apple credentials supplied through the environment
- Centralized application logs and alerts for elevated 5xx responses, queue failures and readiness failures

## Secure configuration

- Use `.env.production.example` only as a key checklist; inject actual values through the hosting secret manager.
- Generate APP_KEY once and keep it in the production secret manager
- Set APP_ENV=production, APP_DEBUG=false and secure session cookies
- Restrict CORS and trusted proxy configuration to known application origins and proxies
- Give administrators least-privilege roles and review immutable audit events regularly
- Back up the database and private export storage; verify restore procedures before launch
- Never commit provider secrets, signing keys or production environment files

## Release procedure

1. Run `php artisan soul:config-check --production` and resolve every failed check.
2. Confirm the branch CI suite, frontend build and dependency audits are green.
3. Install locked PHP dependencies with production flags.
4. Install locked Node dependencies and build the React administration assets.
5. Run database migrations with the production confirmation flag.
6. Cache Laravel configuration, routes and views.
7. Restart queue workers and confirm the scheduler is active.
8. Run `php artisan soul:smoke --base-url=https://staging.example.com` against staging.
9. Smoke-test authenticated onboarding, discovery, messaging, moderation and privacy export flows.
10. Monitor errors, latency and queue depth during rollout; use the previous release artifact for rollback.

The automated smoke command performs GET requests only against health, readiness and bootstrap. It does not create users, mutate records or expose configuration values.

## Recurring operations

- The soul:cleanup command runs daily and removes expired private export files and stale OTP records.
- Run queue failure monitoring continuously and retry only idempotent jobs after investigation.
- Review dependency audit results on every proposed release.
- Test backups and account-deletion execution in a non-production environment regularly.
