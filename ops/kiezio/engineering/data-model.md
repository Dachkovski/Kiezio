# Initial Data Model

This is a domain model, not a finalized database schema.

## Identity

### User

- `id`
- `created_at`
- `status`: active, limited, suspended, deleted
- `age_gate_status`
- `terms_version_accepted`
- `privacy_version_accepted`
- `deleted_at`

### IdentityCredential

- `id`
- `user_id`
- `type`: passkey, email, phone, apple
- `verified_at`
- `encrypted_identifier`
- `created_at`

### PublicPersona

- `id`
- `user_id`
- `area_scope`
- `display_handle`
- `avatar_seed`
- `created_at`
- `rotates_at`

## Location

### AreaCell

- `id`
- `cell_system`: h3, s2, geohash, custom
- `cell_level`
- `parent_cell_id`
- `active_population_estimate`
- `posting_enabled`
- `display_enabled`
- `last_threshold_check_at`

### UserAreaEligibility

- `id`
- `user_id`
- `area_cell_id`
- `confidence`
- `source`: approximate_location, verified_home_area, travel_grace
- `expires_at`

## Content

### Post

- `id`
- `author_user_id`
- `persona_id`
- `area_cell_id`
- `channel_id`
- `body`
- `media_asset_id`
- `status`: pending, visible, hidden, removed, legal_hold
- `created_at`
- `visible_after`
- `expires_at`
- `moderation_state`

### Comment

- `id`
- `post_id`
- `author_user_id`
- `persona_id`
- `body`
- `status`
- `created_at`

### Reaction

- `id`
- `target_type`: post, comment
- `target_id`
- `user_id`
- `type`: useful, funny, thanks, downrank
- `created_at`

### Channel

- `id`
- `area_scope`
- `name`
- `status`
- `created_by_user_id`
- `created_at`

## Safety

### Report

- `id`
- `reporter_user_id`
- `target_type`
- `target_id`
- `reason_code`
- `free_text`
- `area_cell_id`
- `status`: open, triaged, actioned, rejected, duplicate
- `created_at`

### ModerationCase

- `id`
- `source`: report, classifier, staff, legal, emergency
- `severity`
- `status`
- `assigned_reviewer_id`
- `created_at`
- `resolved_at`

### ModerationAction

- `id`
- `case_id`
- `actor_type`: system, reviewer, admin
- `target_user_id`
- `target_content_id`
- `rule_id`
- `action_type`: hide, remove, warn, limit, suspend, ban, restore
- `user_facing_reason`
- `internal_note`
- `created_at`

### Appeal

- `id`
- `user_id`
- `moderation_action_id`
- `status`: open, upheld, overturned, partial
- `user_message`
- `reviewer_note`
- `created_at`
- `resolved_at`

### BlockMute

- `id`
- `user_id`
- `target_user_id`
- `type`: block, mute
- `created_at`

### VideoCallSession

- `id`
- `caller_user_id`
- `recipient_user_id`
- `source_type`: post, comment, profile
- `source_id`
- `status`: requested, accepted, active, ended, declined, blocked, reported
- `started_at`
- `ended_at`
- `report_case_id`

### VideoCallConsent

- `id`
- `session_id`
- `user_id`
- `accepted_safety_terms_at`
- `camera_permission_granted`
- `microphone_permission_granted`
- `created_at`

## Audit

### StaffAccessLog

- `id`
- `staff_user_id`
- `resource_type`
- `resource_id`
- `reason_code`
- `created_at`

### DataRequest

- `id`
- `user_id`
- `type`: export, delete
- `status`
- `created_at`
- `completed_at`

## Design Notes

- Keep identity credentials out of content tables.
- Do not store raw coordinates on posts.
- Use area cells and eligibility records with expiration.
- Keep moderation actions append-only.
- Do not expose internal IDs to public clients.
- Do not store call recordings. Store only privacy-minimized call metadata needed for safety, abuse prevention, and legal holds.
