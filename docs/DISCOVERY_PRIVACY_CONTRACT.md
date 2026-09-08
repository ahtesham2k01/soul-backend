# SOUL V1 discovery and distance contract

This is the practical Flutter/backend contract for discovery filters and privacy. Laravel decides eligibility and ranking; Flutter only sends preferences and renders the returned candidate data.

## Discovery preferences

`PUT /api/v1/discovery/preferences` accepts the required gender/age fields plus:

- `religion_mode`: `my_religion` or `all_religions`.
- `location_mode`: `current`, `selected` or `anywhere`.
- `radius_km`: optional integer from 1–500; `null` means no radius limit.
- `selected_locations`: up to 10 country/city objects. At least one is required for `selected` mode.
- `intentions`: zero to three V1 intention values. An empty list means any intention.

Selected locations and intentions are replaced atomically when their arrays are supplied. Omitting an array preserves the saved list.

## Eligibility and ranking

- A paused, blocked, suspended or non-live profile never appears.
- Profiles active within 30 days rank before older eligible profiles.
- Profiles inactive for more than 90 days are hidden.
- Incognito profiles appear only to members they have already liked.
- Passed profiles can return after 30 days; liked profiles stay excluded.
- All filters are combined. A candidate must pass every selected filter.

Authenticated API activity updates `last_active_at` at most once every 15 minutes, avoiding a database write on every request.

## Distance privacy

Flutter sends exact coordinates only when saving its own profile. Laravel never returns exact coordinates. Candidate responses contain a stable translation key such as `distance.less_than_1_km`, `distance.about_2_km`, `distance.about_5_km` or `distance.more_than_50_km`.

Radius filtering uses an indexed coordinate bounding box followed by an exact server-side distance check. Flutter must not calculate distance itself or display a more precise number than the returned band.

## Contact privacy

`PUT /api/v1/privacy/contacts` replaces the current user's uploaded phone list. The request accepts at most 500 phone numbers and returns only the stored count. Laravel normalizes and keyed-hashes numbers; raw uploaded contacts and hashes are never returned.

Set `hide_contacts: true` in `/privacy/settings` to exclude matching accounts. Set `profile_paused: true` to leave discovery while keeping existing matches/chat. Set `incognito: true` to be visible only to people the member liked.

## Flutter handling

Use the normal error envelope. `DISCOVERY_LOCATION_REQUIRED` means the member selected a radius without saving coordinates. Do not silently change filters; open the location step and let the member decide.
