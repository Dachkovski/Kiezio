# Xcode Workspace Rules For Kiezio

These rules apply once an iOS/Xcode workspace exists for Kiezio.

## Project Identity

- Product name: `Kiezio`
- Current local bundle ID: `dennis.Kiezio`
- Replace placeholder bundle IDs before TestFlight or App Store submission.
- Keep display name, bundle ID, app group, keychain group, push topic, and Associated Domains documented in one project settings file.

## Platform And UI

- Use SwiftUI for new UI unless a specific UIKit API is required.
- Keep views small and compose reusable components.
- Avoid marketing screens as the first screen. The first usable surface should be onboarding into local feed permissions and safety terms.
- The app must work with Dynamic Type, VoiceOver labels, Reduce Motion, and approximate location.

## Privacy And Entitlements

- Location permission copy must state that Kiezio uses approximate area for local posts and does not show exact location to other users.
- Do not request background location in MVP.
- Do not request contacts, photos, microphone, camera, notifications, or location until the feature that needs it is used.
- User-to-user video chat is in scope only as an explicit, voluntary flow. Keep camera/microphone permission prompts feature-triggered, show safety copy before connecting, and keep end-call/report/block controls visible.
- Add `PrivacyInfo.xcprivacy` when the project is created and review it before every release.
- Keep `Info.plist` privacy strings specific and user-facing.

## Safety UX Requirements

Every build intended for external testing must include:

- terms acceptance before viewing/posting UGC;
- report action on posts and comments;
- block and mute action;
- appeal entry point after enforcement;
- account deletion entry point;
- support/contact link;
- visible community rules.
- video-call safety gate before camera/microphone activation when video chat is enabled.

## Testing

Required test areas:

- location bucket creation and sparse-area merging;
- no exact coordinate persistence in normal post flows;
- report, block, mute, and appeal state transitions;
- moderation rule reason display;
- account deletion request flow;
- feed filtering when users block or mute each other;
- accessibility smoke tests for key screens.
- video-call permission denial, end-call, mute, camera toggle, and report entry states.

## XcodeBuildMCP Workflow

- Before the first build/run/test in a Codex session, call `session_show_defaults`.
- If project, scheme, and simulator defaults are valid, use `build_run_sim` or the relevant test command immediately.
- Do not manually boot Simulator as a prerequisite unless the XcodeBuildMCP flow requires it.
- Capture simulator logs and screenshots when debugging UI or runtime behavior.

## Review Gates

Do not submit to TestFlight or App Store until:

- UGC controls satisfy Apple Guideline 1.2;
- privacy manifest and permission strings are reviewed;
- legal has approved the product name for the target markets;
- abuse scenarios in `../product/safety-moderation.md` are tested;
- account deletion and support contact are functional.
