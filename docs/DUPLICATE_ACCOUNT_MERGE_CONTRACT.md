# Duplicate account review and merge

A wrong merge can expose private data, so this flow is intentionally conservative.

1. A super admin opens a case with two public user IDs and a reason.
2. The API records safe signals such as a matching verified social-account email.
3. The API returns `merge_assessment.safe_to_merge` and blocker codes.
4. Merge requires the exact confirmation `MERGE ACCOUNTS`, retained account ID, and a detailed reason.

Automatic merge is refused when the duplicate has a profile, matches/decisions/reports, a conflicting social provider, a scheduled deletion, or either account is an admin. Those cases need manual review.

For a safe auth-only duplicate, social logins and support tickets move to the retained account. Duplicate tokens are deleted, devices revoked, contact fields cleared, and the old account becomes `merged`. The audit log records the decision without private message content.
