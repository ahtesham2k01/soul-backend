# Profile catalogs and member support

Call `GET /api/v1/catalogs/profile?locale=ur` before showing interests, personality traits, or help categories. Store and send the stable `key`; show the localized `label` or `name`. Missing translations safely fall back to English.

Super admins can add, translate, sort, activate, and deactivate profile options. Deactivation hides an option from new selection without deleting old member data. Every admin change requires a reason and creates an audit log.

## Member support flow

1. Load help categories from `GET /api/v1/catalogs/profile`.
2. Create a ticket with `POST /api/v1/support/tickets`.
3. List tickets with `GET /api/v1/support/tickets`.
4. Load a thread with `GET /api/v1/support/tickets/{ticket}`.
5. Reply with `POST /api/v1/support/tickets/{ticket}/replies`.
6. Upload up to three JPG, PNG, or PDF files to the latest member message with `POST /api/v1/support/tickets/{ticket}/attachments`.

Attachments use a private disk and an authenticated download check. Another member receives `404`. Closed/resolved tickets reject new member replies with `409`. Internal admin notes never appear in member responses.
