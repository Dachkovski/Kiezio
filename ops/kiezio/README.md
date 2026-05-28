# Kiezio Ops Project

Kiezio is the working name for a safer hyperlocal community app: local posts and discussions with privacy-preserving location, accountable pseudonymity, transparent moderation, and App Store-ready user-generated-content controls.

This folder captures research, positioning, product requirements, safety policy, privacy architecture, engineering direction, naming notes, and Codex/Xcode workspace rules. The iOS MVP now lives in `../../Kiezio/` with the Xcode project at `../../Kiezio.xcodeproj`.

## Current MVP Status

The local iOS MVP includes:

- onboarding before entering the feed;
- a colorful hyperlocal feed with spaces, categories, quality/new sorting, reactions, replies, and local persistence;
- composer guardrails with character limits and heuristic moderation warnings;
- post and reply reporting with a visible local moderation queue;
- hide, mute, block, appeal, data export, and account deletion request flows;
- a voluntary video-call flow kept behind a small detail-screen action and pre-call safety copy;
- `PrivacyInfo.xcprivacy`, camera/microphone usage strings, and debug self-checks for core MVP behavior.

Latest verified checks:

- iOS simulator build passed with Xcode 26.5 SDK.
- Debug MVP self-check passed for moderation, persistence, feed actions, replies, reports, and hidden-post reload behavior.
- Simulator screenshot smoke test confirmed the feed renders with clear color surfaces instead of a blank screen.

## Why This Exists

Jodel proves that local anonymous feeds can be useful for campus/city questions, spontaneous tips, and everyday local discovery. The public criticism around apps like Jodel also shows the product risk:

- anonymous local feeds can drift into harassment, doxxing, hate, and rumor cycles;
- community-only moderation can feel inconsistent and opaque;
- location-based "anonymous" apps can leak identity through distance, timing, or weak location design;
- minors and vulnerable users need stronger onboarding, reporting, and enforcement;
- App Store user-generated-content requirements must be designed in from day one.

Kiezio takes the useful local-feed mechanic and removes the unsafe assumptions.

## Recommended Name

Use `Kiezio` as the working product name.

Initial screening on 2026-05-24 did not find an obvious same-category App Store / Google Play / web social app conflict for the exact name. This is only a preliminary open-web check, not legal clearance. Before launch, run professional trademark clearance across DPMA, EUIPO, WIPO, USPTO, app stores, domains, and social handles.

## Project Map

- `research/jodel-criticism.md`: source-backed criticism and opportunity mapping.
- `legal/name-clearance.md`: naming recommendation, rejected names, and legal-risk notes.
- `product/product-brief.md`: product vision, audience, MVP scope, non-goals.
- `product/safety-moderation.md`: moderation and trust-and-safety operating model.
- `product/privacy-location.md`: location and identity privacy model.
- `product/roadmap.md`: staged delivery plan.
- `engineering/architecture.md`: high-level system architecture.
- `engineering/data-model.md`: initial domain model.
- `release/store-readiness.md`: current production-readiness status and App Store checklist.
- `xcode/workspace-rules.md`: iOS/Xcode-specific workspace rules.
- `AGENTS.md`: project-specific Codex rules.

## Launch Gate

Do not ship any public beta until these are implemented and tested:

- EULA / terms acceptance with zero tolerance for abusive content.
- In-feed report in two taps or less.
- User block and mute.
- Timely moderation queue with audit log.
- Appeal flow with visible decision reason.
- Account deletion and data export request path.
- Coarse location buckets with k-anonymity thresholds.
- No exact-distance UI.
- Privacy manifest and clear location permission copy.
