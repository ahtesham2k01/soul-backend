# Subscription and entitlement contract

This guide explains subscriptions without hard-coded plans or prices. Laravel decides access; Flutter only renders the returned state.

## Flutter flow

1. Call `GET /subscription/products?platform=ios|android&country_code=PK`.
2. Show only products returned by Laravel. Fetch the display price from Apple or Google using `product_id`.
3. Complete purchase with the platform store. Never send or trust a price entered by the client.
4. After the server has validated the store transaction and activated the subscription, refresh `GET /subscription/entitlements?platform=...`.
5. Use each capability's `enabled`, limit and usage fields for presentation. Laravel must still authorize the action.

Store receipt verification and server notifications require Apple/Google production credentials. A database subscription must never be created from an unverified client claim.

## Capability response

Each key contains `enabled`, `daily_limit`, `daily_used`, `monthly_limit`, `monthly_used` and `source`. A null limit means unlimited. Additive capability keys are expected; unknown keys should be ignored safely.

Resolution order is base feature, plan, country, platform, then individual user override. Scheduled dates and deterministic percentage rollout are applied by Laravel. The backend usage gate increments counters atomically before a limited action.

## Safety invariant

Block, report, account deletion, core privacy, safety appeal and safety support are always enabled and unlimited. Neither a plan nor an admin override may paywall them.

## Admin flow

Only super-admins manage features, plans, country/platform rules, store mappings, promotions and user overrides. Every change requires a reason and creates an immutable audit record. Exact tiers, allocations and prices remain launch configuration—not source code defaults.
