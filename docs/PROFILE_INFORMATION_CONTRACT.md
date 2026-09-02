# SOUL V1 profile information contract

This guide explains the onboarding profile payload in one place. It is written for Flutter, backend and QA developers. The product rules come from `Soul_V1_Product_Requirements.md`; Laravel remains the authority for validation and readiness.

## Endpoints and save behavior

| Method | Endpoint | Use |
|---|---|---|
| `GET` | `/api/v1/onboarding/profile` | Resume the saved draft |
| `PUT` | `/api/v1/onboarding/profile` | Save one or more changed fields |
| `GET` | `/api/v1/onboarding/readiness` | Ask Laravel what is still required |

The update is partial: Flutter may save one screen at a time. Omitted fields keep their previous value. Send an empty value only when the user deliberately clears or skips a field.

```json
{
  "first_name": "Ayesha",
  "date_of_birth": "1997-04-18",
  "gender": "woman",
  "marital_status": "never_married",
  "profession_status": "employed",
  "smoking": "no",
  "alcohol": "no",
  "current_children": "no",
  "future_children": "want_children",
  "intentions": ["marriage"],
  "spoken_language_ids": [1, 2],
  "interests": ["Reading", "Travel"],
  "personality_traits": ["Kind", "Curious"]
}
```

## Required fields

Before submission, readiness requires first name, date of birth (18+), gender, real city/country, nationality, religion, marital status, at least one intention, profession/status, at least one spoken language, the four lifestyle/family answers, an approved public cover and an approved clear-face photo.

Use only these stable values:

| Field | Allowed values |
|---|---|
| `gender` | `man`, `woman` |
| `marital_status` | `never_married`, `married`, `separated`, `divorced`, `widowed` |
| `profession_status` | `employed`, `self_employed`, `student`, `homemaker`, `unemployed`, `retired`, `other` |
| `smoking`, `alcohol` | `no`, `occasionally`, `yes`, `prefer_not_to_say` |
| `current_children` | `no`, `yes_living_with_me`, `yes_not_living_with_me`, `prefer_not_to_say` |
| `future_children` | `want_children`, `do_not_want_children`, `open_to_children`, `not_sure`, `prefer_not_to_say` |

## Optional fields and limits

Optional scalar fields are `bio`, `education`, `height_cm`, `job_title`, `employer`, `grew_up_in`, `ethnic_origin`, `religious_practice`, `prayer`, `diet`, `dress`, `relocation_preference` and `family_involvement_preference`.

- `interests` accepts up to 15 unique, non-empty labels.
- `personality_traits` accepts up to 5 unique, non-empty labels.
- `detailed_religion_visible` defaults to `true`; set it to `false` to hide answered detailed-religion fields from public profile views.

## Skip versus prefer not to say

These are different states:

- Skip: clear the optional value and do not include its name in `prefer_not_to_say_fields`.
- Prefer not to say: clear the value and include its field name in `prefer_not_to_say_fields`.
- Answer later: send the new value; Laravel removes that field from `prefer_not_to_say_fields`.

```json
{
  "education": null,
  "prefer_not_to_say_fields": ["education", "ethnic_origin"]
}
```

Do not send a value and mark the same field as prefer-not-to-say in one request. Laravel returns validation error `422`.

## Flutter model guidance

Keep three states for an optional answer: `unanswered`, `answered(value)` and `preferNotToSay`. Build the request from the changed screen only; do not send a stale full form. Treat response arrays as server truth after each save.

Display validation messages from the standard error envelope. A `401` means the token is invalid, `403` means the account cannot currently use protected APIs, and `422` means one or more fields must be corrected.
