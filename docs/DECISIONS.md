# Architecture and Implementation Decisions

## 2026-10-14 — Audit baseline

- The repository is a generated Flutter application with no existing product architecture or LIFE OS feature code to preserve.
- Keep Android-first scope while avoiding premature platform-specific implementation. Platform support beyond Android should be decided feature by feature.
- Treat the requirements in `PROJECT_SPEC.md` as authoritative. The requested order is the baseline; implementation dependencies may justify documented reordering.
- No final notification, evidence binary storage, or PDF package choices have been made. Select compatible maintained packages during the relevant implementation phase and record exact choices then.
- Firebase is not configured. Do not hard-code project IDs, credentials, or secrets. Authentication and synchronization work depends on creating/configuring a Firebase project and applying reviewed security rules.
- Preserve completion history as immutable event/snapshot records where practical; plan edits must not rewrite historical completion data.
- Keep the adaptive planner rules-based and explainable initially. Schedule changes require explicit approval and an audit trail.
- Keep app-wise usage collection Android-local and permission-gated. Sharing requires explicit user authorization; do not imply remote or real-time device tracking.
- Make no application-code changes during Phase 0. The only Phase 0 deliverables are the audit and project documentation.

## 2026-10-14 — Phase 1 foundation

- Initialized Git because the workspace had no `.git` directory. Git identity was already configured; committed the audited starter as `9f69969` before implementation.
- Adopted `go_router` for declarative route paths and a shell that keeps navigation persistent, with bottom navigation on compact screens and a side rail on wide screens.
- Adopted `flutter_riverpod` as the app-wide dependency/state foundation. No feature state providers or persistence were invented before their feature phases.
- Kept UI foundations in `lib/app`, `lib/core`, and `lib/features/<feature>`; central tokens and Material 3 styling live under `lib/app/theme`.
- Added explicit empty/error/loading widgets for reuse; the initial dashboard intentionally presents an empty state rather than fabricated metrics.
- Android SDK licenses were reported unaccepted by `flutter doctor`; left them unchanged because acceptance is a user action.

## 2026-10-14 — Phase 2 authentication

- Used `firebase_core` and `firebase_auth`, with a repository interface so auth behavior can be exercised through a fake in widget tests without a live Firebase project.
- Firebase initialization uses FlutterFire-generated `DefaultFirebaseOptions.currentPlatform`. The generated options and Android `google-services.json` remain local and ignored by Git; no second Dart-define configuration path is used. If initialization is unavailable or fails, the auth gate shows a generic setup screen without printing configuration details.
- Used Firebase SDK `authStateChanges()` and its native session persistence to guard navigation. Passwords are sent directly to Firebase Authentication and are never persisted by LIFE OS.
- Omitted public registration from the app. Added server-side Identity Platform `beforeUserCreated` and `beforeUserSignedIn` blocking functions with a deployment-time email allowlist for exactly the two intended addresses. The client is not treated as the access-control authority.
- No Firebase project configuration or account addresses were supplied. The blocking functions are written and locally unit-tested, but are not deployed; therefore the two-account restriction is not active until the user completes Firebase setup. Deployment requires Identity Platform and Cloud Functions billing setup.
- No Firestore database, rules, remote synchronization, or remote profile documents were added; those remain future work.

## 2026-10-14 — Phase 3 local data foundation

- Adopted Drift over SQLite for typed queries, reactive local reads, and explicit schema migrations. Production database files live in the application support directory; tests use in-memory SQLite.
- Use the authenticated Firebase UID as the stable local profile key and record owner key. Never derive identity from email or seed UIDs. Profile display names are supplied explicitly by the caller.
- Store future feature data as JSON payloads in a shared record envelope with a constrained kind (`task`, `routine`, `goal`, `habit`, `prayer`, `fasting`, `learningEvidence`, or `screenTimeSummary`). Common ownership, visibility, timestamps, revision, deletion, and sync fields remain typed SQLite columns. Feature-specific validation and screens remain future work.
- Store timestamps as UTC epoch milliseconds and retain an optional IANA timezone ID for interpreting future wall-clock schedules. Soft deletion uses a tombstone so a future sync can propagate deletions.
- Current schema version is 2. Version 2 adds nullable `deleted_at_utc_ms` to the version 1 record table; migrations use Drift's `MigrationStrategy` and are covered by a fixture upgrade test.
- Local edits remain `localOnly`. Conflicting remote snapshots are preserved as a conflict payload and are never silently merged. A remote data-source contract exists, but there is no Firestore adapter, sync worker, upload queue, or remote write path.
- Local owner checks and visibility queries prevent accidental cross-account access in this app process only. They are not security controls. No personal data may be uploaded until Firestore rules are authored and tested against ownership and explicit sharing requirements.
- The two-user Identity Platform allowlist remains undeployed. The Firebase project may still permit any existing email/password account to authenticate.

## 2026-10-14 — Phase 3 local data hardening review

- Bind repository access to the Firebase Auth current UID through an identity interface. Public repository methods no longer accept a caller-provided UID; watch streams rebind and cancel on auth-state changes.
- Validate local record payloads and metadata before writes, enforce optimistic revision checks, keep tombstones idempotent, and reject implicit edits/deletion of unresolved conflicts.
- Keep SQLite in app-specific internal storage. OS sandbox/platform storage encryption is useful against other ordinary apps, but the personal nature of future records warrants evaluating app-level database encryption and Keystore-backed key management before real sensitive data is collected. Account authorization, Firestore rules, app-level encryption, and an app-lock flow are separate controls with distinct threat coverage.
- The Android manifest currently has no explicit Auto Backup policy. Since Android defaults Auto Backup on for eligible apps and includes most internal app files, decide whether to exclude this database or protect backup/restore before persisting real records.

## Open decisions

- Firebase project ownership, region, and account provisioning process for the two named users.
- Whether Firebase Storage is the selected private evidence backend, and its retention limits.
- Exact local timezone behavior for records when users travel or timezone settings change.
- Backup, retention, and deletion expectations for personal records and evidence.
- Whether the currently generated non-Android platform folders should remain supported long-term.
- Firestore document layout, tested ownership/sharing security rules, server timestamps, retry/backoff, idempotency, and manual conflict-resolution UX before remote synchronization is enabled.
- Whether the future prayer, learning, screen-time, and reporting payloads should use dedicated relational tables.

## 2026-10-14 — Phase 4 planning and tracking

- Kept task, routine, goal, and habit definitions in the existing versioned `stored_records` envelope. The shared repository continues to validate ownership, visibility, optimistic revisions, local-only sync metadata, and deletion tombstones.
- Added additive schema version 3 `activity_history` for immutable completion snapshots and goal measurements. Definitions and history are separate so edits to future plans do not rewrite past activity. A unique `(owner_uid, definition_id, kind, occurrence_key)` constraint enforces one habit check-in per local date and one result per scheduled task/routine occurrence.
- Stored recurrence as one-time, daily, weekdays, or a selected weekday. This deliberately avoids a recurrence dependency and leaves monthly/interval schedules and reminders for later design.
- Scheduled date and wall-clock minute are interpreted in the device's current local calendar/time. No IANA timezone identifier is captured by these forms yet; travel/timezone changes remain an open product decision.
- Shared definitions may be viewed and their completion/progress history can be recorded separately by each authenticated local account. History queries check the event's saved visibility and the definition's current state, hiding other-account events if the definition becomes private, is archived, or is tombstoned.
- All feature writes remain local-only. The UI states this directly; no remote adapter or upload behavior was introduced. Local ownership and sharing checks remain safeguards inside the app, not security boundaries.
