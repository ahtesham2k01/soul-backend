# Verification and badges

SOUL keeps verification checks separate so Flutter never turns one approval into a misleading “fully verified” label.

## The four checks

| Key | Meaning | Public badge |
|---|---|---|
| `email` | Login/account email was confirmed | No |
| `phone` | Phone number was confirmed | Yes |
| `selfie` | A moderator approved the selfie/face review | Yes |
| `identity_age` | A moderator approved the ID/age review | Yes |

Call `GET /api/v1/verification/summary` for the current user. Each entry has `status`, `verified`, `requirement` and `blocks_profile`. Treat unknown future status values as unverified.

## Optional and required checks

Requests created by a user are `optional`. Pending or rejected optional requests do not pause discovery or remove an existing live profile. A future safety/risk workflow can create a `required` case; while unresolved it returns `blocks_profile: true` and the safety flow controls profile state.

Only `approved` together with `verified_at` earns a badge. Rejection or appeal availability removes it. Email and phone timestamps remain independent of moderator cases.

## Public privacy

Public profile responses expose only `verification_badges.phone`, `verification_badges.selfie` and `verification_badges.identity_age` booleans. Never display or log a case reason, reviewer note, internal ID, document, provider payload or exact verification time from another member.

## Flutter screen behavior

1. Load the summary when opening Profile > Verification.
2. Show each check as its own row; do not combine them into “fully verified”.
3. Allow optional selfie and identity/age requests only after the API confirms an approved clear-face photo.
4. After submission, poll the cases/summary on screen resume; do not invent a completion time.
5. If `blocks_profile` is true, use the backend correction/lifecycle response instead of bypassing the requirement.
