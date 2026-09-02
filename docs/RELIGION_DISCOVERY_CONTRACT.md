# SOUL V1 religion discovery contract

This guide explains how religion selection affects discovery. The rule is intentionally simple: V1 matches at the top religion/belief level only.

## Product rule

- `my_religion` is the default.
- `all_religions` is the only alternative.
- The choice is saved until the member changes it.
- A member under any Islam sect sees every eligible Islam profile in My Religion mode. The same rule applies to Christianity, Hinduism and every other configured root.
- Sect, tradition, denomination, sub-sect, school, movement, caste and community never change V1 filtering or ranking.

## Data flow

When onboarding saves the final selected religion node, Laravel also stores its root node. For example, `Islam / Sunni / Hanafi` stores Hanafi as the selected node and Islam as the discovery root. This avoids expensive hierarchy traversal on every candidate request.

Every node in the selected path must be active and available for the supplied country. A global child cannot bypass a country-restricted parent.

## Flutter API usage

Save the mode with the normal preferences endpoint:

```http
PUT /api/v1/discovery/preferences
```

```json
{
  "preferred_gender": "woman",
  "minimum_age": 24,
  "maximum_age": 35,
  "same_country_only": true,
  "religion_mode": "my_religion"
}
```

The response always returns the effective mode. Older requests that omit the new field safely use `my_religion` for a new preference and preserve the stored mode for an existing preference.

Candidate results include only the public root religion identifier and slug. Provider IDs, internal database IDs and private religion details are not returned.

## Important errors

| Code | Meaning | Flutter action |
|---|---|---|
| `DISCOVERY_RELIGION_REQUIRED` | My Religion was selected but no valid root is saved | Open religion onboarding |
| `RELIGION_OPTION_UNAVAILABLE` | Part of the selected hierarchy is inactive or unavailable in that country | Reload country-aware options |
| `RELIGION_SELECTION_INCOMPLETE` | The selected node still has another available step | Continue to the next religion screen |

Flutter must fetch the country-aware hierarchy from Laravel. Never hard-code sects, skip rules or country availability in the app.
