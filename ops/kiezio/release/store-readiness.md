# Kiezio Store Readiness

Last checked: 2026-05-25

## What Works Locally

- iOS Simulator Debug build succeeds.
- iOS Simulator Release build succeeds.
- Generic iOS Release build succeeds when code signing is disabled, so Swift code and assets compile for device.
- App icon assets are present and generated reproducibly with `scripts/generate_app_icon.swift`.
- `PrivacyInfo.xcprivacy` declares `UserDefaults` with reason `CA92.1`.
- Onboarding requires explicit community-rule acceptance before UGC surfaces.
- Feed, spaces, categories, sorting, reactions, replies, report, hide, mute, block, local persistence, data export, and local account-data deletion are implemented.
- Composer and reply entry run local heuristic moderation before content is posted.
- Post, reply, and video-call reports land in the local moderation list.
- Video calls require explicit safety acceptance, camera/microphone permission, and expose end, mute, camera, report, and block controls.
- Debug self-check passes for moderation, persistence, core feed actions, replies, reports, video reports, data export, hide reload, and local account-data deletion.

## Current Local Test Results

- `xcodebuild -configuration Debug -sdk iphonesimulator`: pass.
- `xcodebuild -configuration Release -sdk iphonesimulator`: pass.
- `xcodebuild -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO`: pass.
- Simulator self-check: `KIEZIO_SELF_CHECK: PASS`.
- Simulator screenshot smoke test: pass.

## Not Yet Production Complete

- Backend moderation is still local-only. Public launch requires a live server-side report queue, SLA, audit log, and trained human review for severe abuse.
- Feed data is mock/local. Public launch requires backend identity, posting, feed delivery, deletion, export, moderation, and abuse-rate-limit APIs.
- Support, terms, and privacy URLs are configured as `https://kiezio.app/...` and must be live before App Review.
- App Store privacy nutrition labels must match the real backend and analytics stack. The current app declares no collected data because the local build sends nothing off-device.
- Legal name clearance for `Kiezio` is preliminary only.
- Device/App Store signing was not completed locally. A no-sign generic iOS build passes; final archive/upload needs valid Apple Developer Program signing in Xcode or CI.
- Full UI automation via XcodeBuildMCP is blocked until local `xcode-select` points to the full Xcode install instead of CommandLineTools.

## Store Submission Checklist

1. Enroll or confirm Apple Developer Program membership.
2. Create the App Store Connect app record for `Kiezio`.
3. Pick the final bundle ID and update `PRODUCT_BUNDLE_IDENTIFIER` if `dennis.Kiezio` is not final.
4. Publish live pages for support, privacy policy, user privacy choices/data deletion, and terms/community rules.
5. Replace `AppConfiguration` URLs if the final domain differs.
6. Implement and enable production backend services for UGC, moderation, reports, block/mute, account deletion, data export, and video-call signaling if video ships.
7. Update App Store privacy responses based on real data collection.
8. Re-run Debug, Release simulator, no-sign device, and signed archive builds.
9. Test on at least one physical iPhone and one iPad form factor.
10. Capture required App Store screenshots and optional preview video.
11. Fill metadata: name, subtitle, description, keywords, support URL, marketing URL, privacy URL, category, age rating, copyright, review notes.
12. Provide review notes that explain local feed, UGC controls, report/block/mute, account deletion, data export, and video safety gate.
13. Upload an archive through Xcode Organizer or CI, wait for processing, select the build in App Store Connect, add it for review, then submit.
