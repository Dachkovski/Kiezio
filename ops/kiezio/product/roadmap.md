# Roadmap

## Phase 0 - Research And Risk Setup

Status: started.

Deliverables:

- Jodel criticism research.
- Name screening and working name.
- Safety, privacy, and moderation baseline.
- Codex and Xcode workspace rules.
- Initial threat model for location and UGC.

Exit criteria:

- Legal review path identified.
- MVP non-goals agreed.
- Launch-blocking safety requirements documented.

## Phase 1 - Prototype

Goal: prove local feed mechanics without public release.

Deliverables:

- iOS prototype with local feed, posts, comments, reports, block, mute.
- Coarse location bucket module with unit tests.
- Mock moderation queue.
- Privacy onboarding and terms acceptance.
- Seeded test data for one fake city/campus.

Exit criteria:

- No exact location shown or stored in normal flows.
- Report/block/mute reachable in two taps or less.
- Basic App Review UGC checklist satisfied in prototype.

## Phase 2 - Trust And Safety MVP

Goal: make moderation operational before real users.

Deliverables:

- Moderation backend with audit logs.
- Appeals flow.
- Policy rule IDs and user-facing decision reasons.
- Abuse rate limits.
- Reviewer dashboard.
- Data deletion/export request path.

Exit criteria:

- Abuse scenarios in `safety-moderation.md` tested.
- Moderator action audit log complete.
- Appeal SLA metrics available.

## Phase 3 - Private Beta

Goal: validate one local community with controlled invite.

Deliverables:

- Invite system.
- One launch area.
- Staffed moderation schedule.
- Incident response runbook.
- Privacy policy, terms, and contact page.
- Security review of auth, location, and moderation APIs.

Exit criteria:

- Report response SLA met for 30 days.
- No unresolved severe safety incidents.
- Retention and usefulness metrics justify broader test.

## Phase 4 - Public Beta

Goal: expand carefully after operations prove stable.

Deliverables:

- Multi-area support with sparse-area merging.
- Improved ranking for usefulness.
- Verified local info posts.
- Public status and trust/safety transparency report.

Exit criteria:

- Legal name clearance complete.
- App Store review package complete.
- Support and moderation coverage scales to expected traffic.

## Phase 5 - Launch

Goal: launch only after safety, privacy, legal, and moderation systems are mature.

Launch blockers:

- unresolved name/trademark risk;
- exact location leakage;
- missing report/block/appeal;
- no human review path;
- unclear account deletion;
- no App Store UGC compliance evidence;
- no incident runbook;
- no privacy manifest review.
