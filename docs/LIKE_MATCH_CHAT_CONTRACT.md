# Likes, matches and chat contract

This guide explains the complete V1 interaction flow for Flutter, backend and QA.

## Product rules

- A Like creates a pending request and never expires.
- The sender may withdraw a pending Like before it becomes a Match.
- The recipient may accept or decline. Accepting creates one mutual Match; declining does not notify the sender with private details.
- After matching, either person may send the first message.
- V1 messages contain text and emoji only. Photos, voice notes and calls are outside V1.
- Read receipts are always visible. Online/last-seen and typing are available only to active match participants.
- Unmatch hides the conversation from both users and revokes private-photo access. Retained rows support safety, audit and account-export duties.

## Like request flow

1. Send `POST /api/v1/profiles/{profile}/decision` with `decision: like`.
2. The recipient reads `GET /api/v1/likes/received`. Use its cursor for the next page.
3. The recipient sends `PUT /api/v1/profiles/{profile}/like` with `decision: accept` or `decline`.
4. On acceptance, open the returned `match_id`. Repeating an already-completed response returns a safe not-found state.
5. Before acceptance, the sender can call `DELETE /api/v1/profiles/{profile}/like`. The operation is retry-safe.

Never infer whether a hidden, blocked, suspended or unavailable account exists from a 404 response.

## Match and conversation flow

`GET /api/v1/matches` returns the counterpart profile, online/last-seen state, latest message and unread count. Message history uses newest-first cursor pagination. Call the read endpoint when received messages become visible; repeated calls are safe and return zero newly-read messages.

An unmatched, blocked or suspended relationship returns `MATCH_NOT_FOUND` for messages and presence. Flutter should remove that conversation from its local visible list.

## Presence and typing

`GET /api/v1/matches/{match}/presence` returns `is_online`, `last_seen_at`, the counterpart's `is_typing`, and the typing TTL. Online means recent authenticated activity; it is not a guaranteed live socket connection.

Send `PUT /api/v1/matches/{match}/typing` with `is_typing: true` while composing. Refresh before the returned eight-second TTL expires, and send `false` on submit, blur or screen exit. The cache TTL clears stale indicators automatically after crashes or lost connections.

## Flutter implementation checklist

- Keep pending requests, matches and conversations as separate states.
- Use public profile/match/message IDs only.
- Do not show chat controls before `matched` is true.
- Do not cache presence as permanent profile data.
- Mark received messages read only when visible.
- Remove unmatched/blocked chats locally after the API succeeds or returns unavailable.
- Use localization keys for Like, presence, typing and read-receipt labels.
