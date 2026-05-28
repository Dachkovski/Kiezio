# Privacy And Location Model

## Privacy Goal

Kiezio should support local relevance while making it difficult to identify, track, or locate a poster. Location privacy is a product feature, not only a security feature.

## Identity Model

- Users create accounts with a private identity anchor: email, phone, passkey, or platform account.
- Public identity is a pseudonymous local handle.
- Handles may be stable within a local area but should not expose global identity across all cities by default.
- Internal user IDs must not be derivable from public handles.
- Identity data and community activity data should be stored separately.
- Staff access to identity data requires least privilege, audit logging, and reason codes.

## Location Model

### Do

- Use approximate location by default where possible.
- Convert device location into coarse cells on-device or at the API edge.
- Store and rank by coarse cell IDs, not raw coordinates.
- Enforce minimum crowd thresholds before showing or allowing posting in a cell.
- Merge sparse cells into larger areas.
- Use rotating salts or time windows for location-derived identifiers.
- Blur timestamps when location context is sensitive.
- Let users post to a "home area" only after anti-spoof and safety checks.

### Do Not

- Store exact latitude/longitude for normal posts.
- Show exact distance to a post or user.
- Show "very close" labels.
- Show maps of post origins.
- Let users probe location by repeatedly changing device position.
- Allow background location unless a separately justified feature requires it.
- Keep raw location logs by default.

## Feed Eligibility

A post can appear in a local feed only if:

- the post cell meets the k-anonymity threshold;
- the viewer is eligible for the broader local area;
- the post is not in a legal/safety hold state;
- the poster is not blocked by the viewer;
- the post has passed pre-publication checks or human review where required.

## Suggested Thresholds

Initial beta defaults:

- Minimum cell population for posting: 50 recently active eligible users.
- Minimum cell population for display: 100 recently active eligible users.
- Sparse-area merge: expand to district/campus-wide area.
- New-account local posting limit: 3 posts per day, 20 comments per day.
- Exact location retention: zero for normal posts.
- Raw permission event retention: 30 days.
- Moderation incident retention: 12 months, extend only for legal hold.

These are starting values and must be tuned with real abuse and privacy review.

## Threats

- Triangulation by moving viewer position.
- Timing correlation in small communities.
- Identifying a person from local context.
- Staff misuse of identity or location data.
- External scraping of local feeds.
- Bot-created fake local consensus.
- Device ban evasion and account cycling.

## Controls

- Rate-limit location changes and feed refreshes.
- Use server-side anomaly detection for location probing.
- Block feed access from automation and known emulator patterns where appropriate.
- Require device attestation for high-risk actions.
- Use canary posts and scraper detection.
- Log staff access to sensitive data.
- Publish a clear privacy policy and in-app privacy explainer.

## Permission Copy Direction

Avoid vague copy like "enable location to use Kiezio."

Use concrete copy:

- "Kiezio uses your approximate area to show local posts. We do not show your exact location to other users."
- "You can use approximate location. Exact location is not required for the local feed."
- "Posts are grouped into privacy-preserving local areas, not pinned to a map."
