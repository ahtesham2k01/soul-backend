# SOUL V1 documentation index

| Document | Audience | Authority |
|---|---|---|
| `Soul_V1_Product_Requirements.md` | Product, engineering, QA | Confirmed product behavior and source of truth |
| `BACKEND_SCOPE.md` | Backend, product, admin | Implemented versus remaining backend scope |
| `APP_FLOW.md` | Flutter, backend, design, QA | Screen/state sequence and product branches |
| `FLUTTER_DEVELOPER_GUIDE.md` | Flutter engineers | Client architecture and implementation rules |
| `FLUTTER_API_HANDOFF.md` | Flutter/backend engineers | Endpoint, enum and transport contract |
| `PROFILE_INFORMATION_CONTRACT.md` | Flutter, backend and QA | Profile fields, values, limits and answer states |
| `RELIGION_DISCOVERY_CONTRACT.md` | Flutter, backend and QA | Religion modes, root matching and country rules |
| `LOCALIZATION_GUIDE.md` | Flutter, React and backend engineers | Simple translation setup, examples and update checklist |
| `contracts/openapi-v1.json` | Tools and client generation | Machine-readable API contract |
| `contracts/postman-v1.collection.json` | QA and integration | Executable request collection |
| `DATABASE_DESIGN.md` | Backend, data, operations | Current relational design and planned extensions |
| `PRODUCTION_READINESS.md` | DevOps and release owners | Environment, deployment and rollback controls |
| `RELEASE_CANDIDATE_AUDIT.md` | Engineering and reviewers | Security and release verification |
| `../SOUL_V1_BACKEND_PROGRESS.md` | Product and engineering | Persistent phase checklist |

Documentation changes ship in the same complete feature package as behavior changes. Route contracts and required document sections are covered by automated tests to catch drift.
