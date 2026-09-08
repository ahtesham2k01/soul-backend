# Events contract

SOUL V1 supports events created and approved by administrators. Members cannot create public events in V1.

## Member flow

1. Load upcoming published events with `GET /api/v1/events`.
2. Open details with `GET /api/v1/events/{event}`.
3. Join with `POST /api/v1/events/{event}/registration` or leave with `DELETE` on the same path.
4. Report misleading, unsafe, spam or other content with `POST /api/v1/events/{event}/report`.

Joining and leaving are idempotent. Capacity is checked inside a locked database transaction, so two users cannot take the last space. Past, draft and cancelled events are unavailable to members.

## Privacy and online links

The member API never returns an attendee list. It returns only the total registration count and the current member's `is_joined` value. An online meeting URL is returned only to a joined member; list cards and non-members do not receive it.

## Localization

Each event stores translations separately. Laravel chooses the requested locale, then English, then the first available translation. Flutter displays returned `title`, `description` and `locale`; it does not translate admin-written event text locally.

## Admin flow

Super-admin creates a draft, reviews localized content and details, then publishes it. Admin can return it to draft or cancel it with an audited reason. Reports have a private queue and can be resolved, dismissed or used to cancel the event. Reporter identity is not included in the queue response.

Physical events require city and country. Online events require a valid URL. Both support optional capacity, start/end date and an IANA timezone.
