# Architecture Sketch

This is a starting architecture for a privacy-preserving hyperlocal iOS app.

## System Components

### iOS App

- SwiftUI UI.
- Auth and account onboarding.
- Location permission and privacy explainer.
- Local feed, post composer, comments, reports, block/mute, appeals.
- On-device location bucketing helper where feasible.
- Local moderation reason display.

### API Gateway

- Authenticated API surface.
- Request rate limits.
- Device attestation checks for high-risk actions.
- Abuse throttles.
- Privacy-safe logging.

### Identity Service

- Account creation.
- Passkeys / email / phone verification.
- Age gate status.
- Account deletion and export request handling.
- Private identity vault separated from public content data.

### Location Privacy Service

- Converts location into coarse area cells.
- Enforces k-anonymity thresholds.
- Merges sparse cells.
- Detects location probing.
- Provides local feed eligibility.

### Feed Service

- Stores posts/comments by area cell and channel.
- Ranks by relevance, freshness, and quality.
- Applies block/mute filters.
- Avoids exact-distance ranking.

### Moderation Service

- Pre-publication classifier integration.
- Report queue.
- Human review workflow.
- Appeals.
- Rule IDs and decision reasons.
- Audit log.

### Notification Service

- Replies and moderation updates.
- No sensitive content in push payloads.
- User-controlled quiet hours and notification categories.

### Video Call Service

- Request/accept signaling for voluntary 1:1 video calls.
- Camera and microphone permission handling on the client.
- WebRTC media transport behind a replaceable service boundary.
- Visible call controls: hang up, mute, camera toggle, report, and block.
- Rate limits and abuse telemetry for call requests.
- No random matching, exact location display, or recording in MVP.

### Trust And Safety Console

- Queue triage.
- Incident escalation.
- User history summary.
- Appeal handling.
- Reviewer quality review.

## Data Stores

- Postgres for relational product data.
- PostGIS or S2/geohash support only for coarse cells, not raw user coordinates.
- Object storage for images/videos after safety scan.
- Queue system for moderation and notifications.
- Append-only audit log for moderation, staff access, and sensitive data operations.

## Security Requirements

- Encrypt sensitive identity data at rest.
- Use least-privilege service accounts.
- Separate staff tools from public API.
- Audit all staff access to identity, reports, and moderation decisions.
- Rate-limit posting, reporting, login, account creation, and location changes.
- Rate-limit video-call requests and block repeated peer probing.
- Keep raw request logs free of exact coordinates and secrets.
- Use structured incident response for data exposure and safety emergencies.

## Privacy Requirements

- No exact coordinates in normal post records.
- No public exact distance.
- No public global user graph.
- Short retention for raw operational metadata.
- User data export and deletion path.
- Documented legal hold process.

## Open Decisions

- Backend stack: Swift/Vapor, Node/TypeScript, or another existing team preference.
- Location grid: S2, H3, geohash, or custom area polygons.
- Auth provider: first-party passkeys vs. managed provider.
- Classifier strategy: managed moderation APIs vs. self-hosted models plus human review.
- Initial market and age policy.
- Whether public handles rotate by city, channel, or time window.
