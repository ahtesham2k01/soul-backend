# SOUL V1 requirement traceability

This matrix connects every numbered product-requirement section to its implementation evidence. It is the short release-review view; the linked documents explain each flow in developer-friendly language.

| PRD section | Delivery status | Main implementation evidence | Verification evidence |
|---|---|---|---|
| 1. Product scope | Implemented | `BACKEND_SCOPE.md`, `/api/v1` boundary | API contract parity tests |
| 2. Authentication and accounts | Implemented | Email OTP, Apple/Google, Sanctum sessions | Auth endpoint tests |
| 3. Localization and brand | Implemented | Bootstrap catalog, locale negotiation, admin overrides | Bootstrap and catalog completeness tests |
| 4. Required profile information | Implemented | Draft/profile schema and readiness service | Profile information and submission tests |
| 5. Optional profile information | Implemented | Answer states, interests, traits and visibility | Profile information parity tests |
| 6. Religion taxonomy and Version 1 discovery | Implemented | Taxonomy, country rules and root-religion mode | Religion option/profile/discovery tests |
| 7. Discovery | Implemented | Eligibility, filters, decisions and activity ranking | Discovery parity tests |
| 8. Distance privacy | Implemented | Radius filtering and safe distance bands | Advanced discovery tests |
| 9. Photos | Implemented | Three-slot upload, moderation and replacement lifecycle | Photo/session/moderation tests |
| 10. Private photos | Implemented | Match-bound request and protected delivery | Private-photo access tests |
| 11. Screenshot protection | Implemented | No-store contract and capture-event reporting | Private-photo access tests |
| 12. Likes, requests, matches and chat | Implemented | Pending likes, matches, messages, receipts and presence | Matching and messaging tests |
| 13. Marital status | Implemented | Required public card/full-profile field | Marital-status tests |
| 14. Verification | Implemented | Phone, selfie and identity cases/badges | Verification tests |
| 15. Safety, reporting and moderation | Implemented | Report/block, risk cases, appeals and audit | Safety and admin moderation tests |
| 16. Notifications | Implemented | In-app, push/email preferences and event coverage | Notification tests |
| 17. Events | Implemented | Localized events, capacity, reporting and admin controls | Event tests |
| 18. Subscription and dynamic entitlements | Implemented | Dynamic plans, products, limits and promotions | Entitlement tests |
| 19. Legal promise and consent | Implemented | Versioned policies and commitments | Legal-consent tests |
| 20. Profile lifecycle | Implemented | Draft, checks, correction, live, pause and deletion recovery | Submission/readiness/privacy tests |
| 21. Main navigation | Implemented as API contract | Explore, Likes, Chat and Profile data sources | Flutter handoff and route parity tests |
| 22. Explicitly deferred decisions | Deliberately deferred | Listed in `BACKEND_SCOPE.md`; no guessed pricing or out-of-scope media | Scope/documentation tests |
| 23. Implementation principles | Implemented | Server authorization, ULIDs, privacy boundaries, queues and audit logs | Full PHP suite, React build and CI |

## Release interpretation

“Implemented” means the backend behavior, database structure, authorization, API contract, tests and relevant React administration are present. It does not mean external providers or production infrastructure have been configured. Those launch gates are tracked in `RELEASE_CLOSURE.md` and require staging credentials and deployment authority.
