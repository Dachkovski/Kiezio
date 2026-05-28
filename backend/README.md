# Kiezio Backend

Local production-shaped backend slice for the iOS app. It uses only Python standard library modules and SQLite.

## Run

```sh
python3 backend/kiezio_backend.py --host 127.0.0.1 --port 8787 --db backend/kiezio.sqlite3
```

The iOS simulator can reach it at `http://127.0.0.1:8787`.

## Test

```sh
python3 backend/test_backend.py
```

## Implemented Capabilities

- Seeded local feed stored in SQLite.
- User anchor via `X-Kiezio-User-ID`.
- Posts, replies, reactions, hide, mute, block.
- Report queue for posts, replies, and video calls.
- Moderation status changes, SLA timestamps, and audit log.
- Rate limits for posting, replying, reporting, reactions, and controls.
- User data export.
- Account deletion that removes user posts, replies, reactions, and controls while retaining audit entries.
- Deleted user IDs are rejected with `410 account_deleted`; the iOS app rotates its local pseudonymous API ID after deletion.

## Production Notes

This backend is intentionally local and dependency-free. Before public launch, replace or extend it with:

- real authentication and private identity anchors;
- HTTPS hosting and environment-specific configuration;
- human moderation tooling with reviewer roles;
- durable audit export and legal hold rules;
- backup, migration, monitoring, and incident response;
- abuse rate limits by account, IP/device, and trust tier.
