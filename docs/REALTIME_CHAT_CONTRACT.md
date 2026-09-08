# Real-time chat contract

REST remains the source of truth. Real-time events make the UI fast; after reconnect, Flutter reloads messages through the cursor-paginated REST endpoint.

## Connect

1. Call `GET /api/v1/matches/{match}/realtime` with the member bearer token.
2. Use the returned private channel and authorization endpoint.
3. Authenticate the socket with the same bearer token.
4. Subscribe only while the inbox or chat screen needs updates.

Only active match members can authorize. Unmatched, blocked, suspended, or unrelated users are denied.

| Event | Flutter action |
|---|---|
| `chat.message.created` | Append the message if its ID is new. |
| `chat.messages.read` | Update mandatory read receipts. |
| `chat.typing.changed` | Show/clear typing and always auto-clear at `expires_at`. |

Payloads use public ULIDs and never database IDs. Production needs a supported Laravel broadcast transport and credentials; local/test uses the log driver.
