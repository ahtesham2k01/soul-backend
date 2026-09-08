# Marital status contract

This document keeps the V1 marital-status rules clear for Flutter, backend and QA.

## Product rules

- Marital status is required before a profile can go live.
- It cannot be skipped, hidden or changed to “prefer not to say”.
- Supported values are `never_married`, `married`, `separated`, `divorced` and `widowed`.
- The value is present on both the discovery card and full public profile. Flutter should display it near the person's name/age rather than inside a collapsed details section.
- Married people can select any V1 intention: Marriage, Serious relationship and/or Casual dating.
- Married and unmarried people may discover each other. Marital status does not silently filter or rank candidates.
- Partner-consent and polygamy questions are not part of V1 and must not be shown or submitted.

## Discovery card

`GET /api/v1/discovery/candidates` includes `marital_status` beside the existing profile identity fields. Exact date of birth remains private; only calculated age is returned.

## Full profile

`GET /api/v1/profiles/{profile}` returns the safe public profile. It includes marital status and intentions, approved public photos, public religion data and allowed optional answers. Fields marked “prefer not to say” return `null`; marital status is never eligible for that behavior.

The route returns the same non-enumerating `PROFILE_UNAVAILABLE` response for missing, blocked, suspended or inaccessible profiles. A profile paused from discovery remains visible to an existing active match, as required by the pause rule.

## Flutter checklist

- Map enum values through the translation catalog; never hardcode English labels.
- Show marital status on every discovery card and at the top of the full profile.
- Do not add a hide toggle for marital status.
- Do not add partner-consent or polygamy controls.
- Treat unknown future enum values with a safe localized fallback.
