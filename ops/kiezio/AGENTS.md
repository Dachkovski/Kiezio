# Kiezio Project Rules

These rules apply to `ops/kiezio/` and the iOS app implementation in `../../Kiezio/`.

## Product Principles

- Kiezio is a hyperlocal community app inspired by the useful parts of anonymous local feeds, not a clone of Jodel.
- The product must not depend on full anonymity. Use pseudonymity with accountable, private identity anchors.
- Local relevance must never require precise public location, exact distances, or predictable user tracking.
- Community moderation may provide signals, but final enforcement must be auditable and supported by trained human review for serious cases.
- A report, block, mute, appeal, and account deletion path is mandatory before any public beta.

## Safety And Privacy Baseline

- Use coarse, rotating location buckets and k-anonymity thresholds for feeds.
- Never expose exact coordinates, exact distance to a poster, home/work inference, or "very close" labels.
- Default retention should be short. Extend retention only for legal holds, safety incidents, or explicit user-controlled saved content.
- User-to-user video chat is in scope only as a voluntary, pseudonymous, mutual-opt-in flow. No random matching, dating-like discovery, exact location exposure, recordings, or hidden call controls. Private contact requires rate limits, reporting, blocking, visible end-call controls, and safety copy.
- Treat doxxing, harassment, hate, sexual content involving minors, threats, stalking, spam, and impersonation as launch-blocking abuse categories.

## Engineering Defaults

- Prefer SwiftUI for iOS UI and keep privacy-sensitive logic in separately testable modules.
- Use explicit service boundaries for identity, location privacy, feed ranking, moderation, notifications, and audit logging.
- Store raw identity and coarse community activity separately, with least-privilege access and audit logs.
- Do not hard-code secrets, API keys, bundle IDs for production, or store endpoints in source.
- Every feature touching location, moderation, identity, or user-generated content needs tests and a threat-model note.

## Xcode / Codex Workflow

- Keep `ops/kiezio/xcode/workspace-rules.md` aligned before creating or changing an Xcode workspace.
- Run build and tests through XcodeBuildMCP when the project exists and the tool is available.
- Use explicit privacy strings, PrivacyInfo manifests, and entitlement review before simulator testing with location or push features.
