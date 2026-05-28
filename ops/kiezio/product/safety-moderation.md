# Safety And Moderation Model

## Safety Position

Kiezio should be built as a local community product with pseudonymous expression, not as an anonymous chat product. The system should make helpful local participation easy and harmful local targeting hard.

## Policy Categories

Launch-blocking categories:

- Child sexual abuse material or sexual exploitation.
- Credible threats of violence or self-harm.
- Doxxing, including contextual local identification.
- Stalking, targeted harassment, or coordinated dogpiling.
- Hate speech and dehumanizing attacks.
- Non-consensual intimate imagery.
- Sexual solicitation involving minors or ambiguous age.
- Impersonation of local authorities, schools, employers, or emergency services.
- Scam, spam, malware, phishing, and platform manipulation.
- Illegal goods or services.

High-risk but context-dependent categories:

- Rumors about identifiable people.
- Accusations about crimes or misconduct.
- Local emergency reports without evidence.
- Political persuasion in small local clusters.
- Sensitive health, school, workplace, or housing information.

## Moderation Layers

### 1. Pre-Publication Friction

- Text classifier for hate, threats, sexual content, doxxing patterns, and spam.
- Image/video classifier before publication.
- Warning prompt before posts that mention a name, workplace, dorm, school, license plate, address, or exact time/place.
- New-account cooldowns and posting limits.

### 2. Community Signals

- Up/down relevance votes affect ranking only.
- Reports enter moderation queue with category and context.
- Trusted users may add triage signals, but cannot independently ban users or remove severe cases.

### 3. Automated Enforcement

- Temporary rate limits for spam and obvious abuse.
- Auto-hide only for high-confidence, low-ambiguity violations.
- Queue all serious or ambiguous cases for human review.

### 4. Human Review

Human review is mandatory for:

- threats;
- self-harm;
- doxxing;
- hate;
- sexual safety;
- stalking;
- ban decisions;
- appeals;
- law enforcement or emergency requests.

### 5. Appeals

- Every removal, timeout, or ban receives a rule ID and short explanation.
- Appeals must be available in-app.
- Target SLA: 48 hours for normal appeals, 12 hours for account bans, faster for urgent safety issues.
- Track overturn rate by rule, reviewer, classifier, and local cluster.

## Moderator Tool Requirements

- Queue by severity, age of report, and local-risk density.
- View redacted context around the reported content.
- User history with privacy-minimized abuse summary, not full casual browsing.
- Decision templates mapped to policy rules.
- Audit log for every moderation action.
- Escalation channel for legal, safety, and emergency cases.
- Reviewer disagreement and quality review workflow.

## User Controls

Required in MVP:

- Report post/comment in two taps or less.
- Report user from a profile or thread context.
- Block user.
- Mute user.
- Hide thread.
- Appeal moderation decision.
- Delete account.
- Request data export.

Recommended:

- Keyword mute.
- Sensitive topic reduction.
- Local channel mute.
- "Take a break" prompt after heated exchanges.

## User-To-User Video Chat

Video chat is allowed only as a guarded, voluntary 1:1 feature.

Required before beta:

- Start calls only from an existing local context, such as a post or reply.
- Require clear pre-call safety acceptance before camera or microphone activation.
- Require recipient opt-in before real media exchange in production.
- Keep hang up, mute, camera toggle, report, and block controls visible during the call.
- Do not provide random matching, dating-style discovery, exact distance, recordings, screenshots, or hidden re-entry after block.
- Rate-limit call requests by account, device, peer, and local area.
- Add a moderation case type for call reports and preserve only privacy-minimized metadata unless a legal/safety hold applies.
- Show camera and microphone permission prompts only after a user starts the video flow.

## App Store UGC Compliance

Apple Guideline 1.2 requires UGC apps to provide filtering, reporting, timely responses, blocking abusive users, and published contact information. Kiezio should make these controls visible in the first testable build and document them in App Review notes.

Source: https://developer.apple.com/app-store/review/guidelines/

## Abuse Scenarios To Test

- A user posts "whoever lives above the bakery on X street is..." without a name.
- A user posts a class schedule and asks others to identify someone.
- A group downvotes all posts by a political minority in a local cluster.
- A false emergency report spreads in a small area.
- A banned user creates new accounts and reposts the same rumor.
- A user tries to infer a poster's location by changing their own location repeatedly.
- A user reports harmless content using the wrong category.

Each scenario needs product behavior, moderator action, and logging expectations before beta.
