# LIFE OS Implementation Status

Updated: 2026-10-14 (Asia/Dhaka)

## Current status

- Phase 0 (audit): Complete.
- Phase 1 (UI foundation): Complete.
- Phase 2 (authentication): App implementation complete; Firebase project activation and live integration verification are blocked on user setup.
- Phase 3 (offline data architecture): Local foundation implemented; remote synchronization remains disabled.
- Phase 4 (routines, tasks, goals, habits): Implemented with local-only persistence and tests.
- Phase 5: Local data foundation, prayer tracking and notifications, fasting, sleep, workouts, and Home/Insights integration implemented; this milestone awaits review. Device-level notification checks remain.
- Phases 6 and later: Not started.

## Completed

### Phase 0

- Audited the generated Flutter starter, toolchain, Android setup, and dependencies.
- Preserved the complete requirements in `docs/PROJECT_SPEC.md`.

### Phase 1

- Added feature-oriented architecture, centralized theme tokens, responsive navigation, Riverpod, and go_router.
- Added reusable card and loading/empty/error state widgets.
- Added Home, Plan, Goals, Insights, and Settings foundation destinations.
- Initialized Git and recorded the original audit baseline as `9f69969`.

### Phase 2 app and server code

- Added Firebase Core and Firebase Authentication dependencies, FlutterFire-generated Android options, and a fail-closed configuration screen.
- Added Firebase email/password sign-in, sign-out, password reset, safe error messages, form validation, loading states, and generic reset confirmation to avoid account enumeration.
- Added auth-state routing: unresolved auth state shows loading, unauthenticated users are directed to sign-in, and authenticated users can reach the existing app shell. Firebase SDK session persistence is used; passwords are not stored by the app.
- Added no public registration UI. Added Identity Platform blocking functions to permit account creation/sign-in only for the two addresses configured during deployment.
- The sign-in screen now states that the two-user restriction is not active until server-side restrictions are enabled; existing Firebase accounts may otherwise be able to sign in.
- Added authenticated account email and sign-out control to Settings.
- Added Flutter widget tests for missing configuration, protected routes, validation, sign-in/sign-out, reset, and wide layout; added Node tests for allowlist matching.
- Verified the generated Android Firebase options and Android native config identify the same project and match the app's Android application ID. Updated startup to use `DefaultFirebaseOptions.currentPlatform` before `runApp`.
- Added local ignores for generated Firebase options and `google-services.json`; removed the redundant Dart-define/local JSON configuration path.

## In progress

- Remote synchronization planning only. No Firestore reads or writes are implemented.

## Completed implementation details

### Phase 4 routines, tasks, goals, and habits

- Added typed planning definitions over the existing authenticated record repository for tasks, routines, goals, and habits. Create/edit, archive, and tombstone deletion are available; task/routine completions support Done, Partial, Not Done, and optional notes.
- Added once, daily, weekdays, and selected-weekday recurrence. A schedule edit changes only the future definition; prior completion snapshots retain their original title, status, notes, and date.
- Added measurable goals with target date, target value/unit, append-only measurements, recent progress display, and target progress bar.
- Added append-only completion/progress history in Drift schema version 3. Its composite uniqueness key prevents duplicate check-ins for the same user, definition, kind, and occurrence date/time. Existing profile and `stored_records` tables are unchanged; migrations add only the new history table and preserve existing rows.
- Added user-scoped history queries and current shared-visibility checks. A shared item can receive separate per-user completion history; making its definition private, archiving it, or tombstoning it hides its history from the other account. Local filtering remains an application safeguard, not a security boundary.
- Connected Home, Plan, Goals, and Insights to live local database streams. Added validation, loading/empty/error states, and a visible local-only/offline indicator. No feature writes to Firebase or another remote service.
- Added repository tests for validation, recurrence, completion snapshots, duplicate habit check-ins, goal history, account switching, shared/private history, and user isolation; added widget input/save coverage and v1/v2 migration coverage.
- Limits: recurrence supports one-time, daily, weekdays, and selected weekly days; no flexible interval/monthly rules or notification scheduling. Dates use the device's local calendar date and scheduled wall-clock minute; travel/timezone-change policy remains undecided. Deletion is a local tombstone and never erases history. Archived definitions are hidden from active lists and are not yet restorable from an archive view.
- Prayer, fasting, learning evidence, Screen Time, PDF export, AI planning, cloud sync, and server-enforced allowlisting remain unimplemented.

### Phase 5 first milestone: local tracking data foundation

- Increased the Drift schema to version 4 with an additive `tracking_entries` table for date-keyed prayer, fasting, sleep, and workout entries. Added partial unique indexes for active `(owner_uid, kind, local_date, entry_key)` values, the approved one-sleep-entry-per-owner/local-date rule, and owner/date/kind queries. Tombstoned keys may be recreated as new entries without restoring the old row.
- Added strict tracking-entry validation for IDs, owner UID, real local dates, UTC timestamp order, revision values, kind-specific payloads, five named prayer keys, prayer schedule snapshots, fasting statuses, sleep/workout durations, and required workout activity.
- Added an offline repository and Drift store bound to the current Auth UID. Streams switch/cancel on account changes; reads are owner-scoped or explicitly shared; only the owner may update/delete; writes use optimistic revisions and soft tombstones. No remote adapter or cloud write path was added.
- Preserved existing Phase 2/3/4 structures and behavior. Migrations from v1, v2, and v3 now reach v4 sequentially; the v3 fixture confirms profile-linked record payload/revision/tombstone and activity history preservation. All migration/repository tests use in-memory SQLite.
- Approved decisions reflected in the checklist: device-local timezone; 5-minute prayer reminders capped at 6 and stopped at Jamaat or completion; inexact notification with delay warning if exact-alarm access is unavailable; separate notification permission; one sleep entry per user per local wake-up date.
- This milestone does not implement prayer schedules/UI, notifications/permissions/channels, fasting/sleep/workout UI, Home/Insights integration, or dependencies. Those remain pending user review.

## Blocked / external setup required

- The generated Firebase Android options are present locally but ignored by Git. A new checkout must run `flutterfire configure --project <PROJECT_ID> --platforms android` before running/building the app.
- Live sign-in has not been verified. Confirm Email/Password is enabled in the Firebase Console and provision accounts through an administrator before sign-in use.
- Secure two-user enforcement requires upgrading Firebase Authentication to Identity Platform and deploying `functions/` with `LIFE_OS_ALLOWED_EMAILS` set to the two authorized addresses. Create the two accounts through a trusted administrator process. Until those functions are deployed, Firebase Authentication itself is not restricted to the two intended accounts.
- No live Firebase Authentication or emulator test has been run. The Flutter tests use a fake repository; Node tests exercise allowlist normalization/matching. No account passwords or Firebase admin credentials were requested or used.
- Android SDK licenses were reported as accepted by `flutter doctor -v` during the Firebase configuration verification; this audit did not change license settings.

## Pending

- Phase 2: Configure and verify the real Firebase project, Identity Platform restrictions, and the two accounts.
- Phase 3 remaining: Design and test Firestore security rules before implementing any remote adapter or upload path. Local ownership checks are not a server security boundary.
- Phase 4: Complete; prior review accepted it for continued development.
- Phase 5 remaining: Manual Android notification verification across supported Android versions/devices. Fasting and wellness are implemented locally in this milestone and await review.
- Phase 6: Learning sessions and private evidence.
- Phase 7: Android Screen Time collection and permission handling.
- Phase 8: Shared progress, comparison, leaderboard, and analytics.
- Phase 9: Reports, PDF preview, device save/share, and JSON export/import.
- Phase 10: Approval-based adaptive planning and rolling 14-day plans.
- Phase 11: End-to-end, accessibility, performance, security, and release validation.

## Verification results

- `dart format lib test`: Phase 4 run recorded below.
- `flutter analyze`: Phase 4 run recorded below.
- `flutter test`: Phase 4 run recorded below.
- `npm test --prefix functions`: 3 allowlist unit tests passed.
- `node --check functions/index.js`: passed.
- Live Firebase sign-in/emulator integration: not run. No account creation, auth-provider change, Cloud Functions deployment, or security-rule change was performed.
- Android build: not run in this audit. Android SDK licenses were reported accepted by `flutter doctor -v` during Firebase configuration verification.

### Phase 4 verification

- `dart format lib test`: passed; all 29 Dart files checked, with no remaining formatting changes.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed, 32 tests total (12 planning repository tests, 1 planning widget test, 13 record/database tests, and 6 existing auth/foundation widget tests).
- `git diff --check`: passed; Git emitted only working-tree LF-to-CRLF normalization notices.
- No Android build or live Firebase integration was run. No remote writes, account creation, Cloud Function deployment, billing change, or Firestore rule change was performed.

### Phase 5 first-milestone verification

- `dart run build_runner build`: passed; regenerated Drift database code for schema v4.
- `dart format lib test`: passed; all 33 Dart files checked, no remaining formatting changes.
- `flutter analyze`: passed with no issues.
- `flutter test`: passed; 40 tests total, including 7 tracking repository tests and v1/v2/v3 migration coverage.
- `git diff --check`: passed.
- No notification dependency was installed, no Android/Firebase configuration was changed, and no production database was opened.

### Phase 5 prayer UI and local tracking milestone

- Added a typed manual prayer schedule for Fajr, Dhuhr, Asr, Maghrib, and Isha with separate Azan/Jamaat time editors, validation, private-by-default storage through the existing prayer record kind, and a revisioned local schedule record.
- Added a prayer screen with device-local date selection, explicit Prayed on time / Prayed late / Missed choices, optional Jamaat status and notes, and an unrecorded state when no entry exists. The initial schedule must be configured manually; prayer times are not calculated.
- Added an Android system-timezone method channel. Each new prayer entry saves a local date and a snapshot of that prayer's Azan/Jamaat minutes and current IANA timezone. Editing schedule values or timezone only affects future entries; existing snapshots and local dates remain unchanged.
- Prayer schedule and dated entries use the active Firebase UID through the current local repositories. Records remain private and local-only; no Firestore writes or server-side enforcement were added.
- Added repository tests for schedule validation/privacy, dated status writes, snapshot retention across schedule/timezone changes, unrecorded entries, malformed dates, and account isolation; added widget tests for setup empty state, prayer recording, and schedule validation.
- No notification dependency, notification permission, channel, or alarm scheduling was added. Notifications are a separate milestone awaiting review of this prayer UI/data flow.

### Phase 5 prayer notification milestone

- Added `flutter_local_notifications` 22.3.2 and direct `timezone` 0.11.2 after checking compatibility with Flutter 3.41.2/Dart 3.11.0, Android SDK 36, AGP 8.11.1, Java 17 compile settings, and current plugin setup guidance. The existing Android system-timezone bridge remains the only device timezone source; `flutter_timezone` was not added.
- Added a `PrayerReminderService` abstraction, local Android adapter, injectable clock/timezone/gateway boundary, and a Riverpod lifecycle controller. It initializes the timezone database, validates the returned IANA ID against the timezone database, and fails closed without scheduling on lookup errors; there is no UTC fallback.
- Users opt into reminders in Prayer Settings, then explicitly tap the notification permission control. Notification posting permission and exact-alarm access are checked independently. If notification permission is denied, no reminders are scheduled. If notifications are allowed but exact-alarm access is unavailable, Android inexact-while-idle scheduling is used with a visible delay warning. `USE_EXACT_ALARM` is not declared.
- Schedules use the device's current local timezone and a seven-local-day horizon. Each prayer session gets a stable deterministic ID for Azan, up to six five-minute reminders strictly before Jamaat, and one optional snooze. Past triggers are skipped. Completion, dismissal, disabled reminders, schedule edits, account changes, permission checks on resume, and detected date/timezone changes reconcile pending IDs. Dismissal, snooze-use, and notification-action disable state are stored in a separate private/local prayer-kind record bound to the Auth UID.
- Added notification actions to snooze once, dismiss one prayer session, or turn off reminders. Completion records immediately cancel that prayer session's pending and active notifications. Startup clears stale managed notifications before scheduling only the currently authenticated UID's data; app resume and auth changes reconcile again. Android boot/package-replacement receivers restore the plugin-managed schedule.
- Added `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `SCHEDULE_EXACT_ALARM`, scheduled-notification/action/boot receivers, and core library desugaring 2.1.5. AGP already matched the plugin's documented 8.11.1 minimum and Flutter resolves compile SDK 36. No `USE_EXACT_ALARM` declaration or Firebase configuration change was made. No database migration was needed: existing schedule payloads default the new opt-in setting to disabled, and suppression state uses the existing record envelope.
- Automated tests cover notification denial vs exact access, inexact fallback and warning, stable IDs/idempotence, past triggers and Jamaat cutoff, completion and dismissal, schedule edits, permission revocation, timezone changes/failures, account switching, snooze/disable actions, and resume reconciliation. These fake-gateway tests do not prove Android delivery.
- Limitations: notification delivery can be late or suppressed by Doze, force-stop, user settings, or OEM battery controls. Boot recovery, permission prompts, exact-alarm settings, channel preferences, and timezone/date changes still need manual Android device/emulator verification. The app does not claim a scheduled notification was delivered. Remote synchronization and server-side two-account enforcement remain unimplemented.
- Verification: `dart format lib test` passed (47 Dart files); `flutter analyze` passed; `flutter test` passed (70 tests); `flutter build apk --debug` passed; `git diff --check` passed. The first build attempt hit corrupted cached 2.1.4 desugaring artifacts; after switching to compatible 2.1.5 and refreshing Gradle dependencies, the APK build succeeded. No project clean, device install, notification prompt, account operation, Firebase change, or commit was performed.

### Phase 5 fasting and wellness milestone

- Added fasting records with date-specific Fasted/Not fasted values, optional notes, an explicit unrecorded state, history, revision-checked edits, and tombstone deletion.
- Added one sleep-duration record per authenticated UID and local wake-up date, 1–1440 minute validation, optional notes, revision-checked edits, and safe tombstone deletion. Local dates are retained as entered; timezone changes do not rewrite history.
- Added workout logging with activity, 1–1440 minute duration, optional notes, date selection, multiple entries per date, editing, history, and tombstone deletion.
- Added dedicated Fasting and Wellness routes outside the five primary navigation destinations. Home shows current-day fasting/sleep/workout summaries and Insights shows recent recorded fasting, sleep, and workout summaries. Unrecorded fasting dates are not counted as missed.
- All features reuse schema v4 and the authenticated UID-bound local repository. Records default to private; no remote write or synchronization path was added. Repository ownership/visibility checks remain application safeguards, not a server security boundary.
- Workflow tests cover local-date handling, historical-date preservation during edits, private defaults, unrecorded dates, multiple workouts, deletion, and signed-out failure. Widget tests cover fasting recording, sleep validation, local saving, and multiple workout entries. Migration/schema and account-isolation behavior continue to be covered by the existing tracking repository tests using in-memory SQLite.
- Limitations: dates are manually selected using the device's current local calendar; sleep stores a single total duration per wake-up date and no stages. Home and Insights summaries use owned records only. Android notification delivery still requires the manual device checks listed in `docs/PRAYER_NOTIFICATION_SMOKE_TEST.md`.
- Verification: `dart format lib test` passed (53 Dart files; 2 reformatted); `flutter analyze` passed with no issues; `flutter test` passed (76 tests); `flutter build apk --debug` passed. `git diff --check` is run after the final documentation edit.

## Scope boundary

Phase 2 establishes authentication only. Firestore profiles, data ownership rules, synchronization, and cross-device records are not implemented. No Firestore rules were created or changed. The app must not be described as synchronized or complete until later phases implement and verify those behaviors.

### Phase 3 local persistence

- Added Drift/SQLite schema version 2 with UID-keyed profiles and a versioned record envelope for tasks, routines, goals, habits, prayer, fasting, learning-evidence metadata, and screen-time summaries.
- Added local repository and store interfaces, UTC millisecond timestamps, optional timezone IDs, local-only sync state, revision tracking, conflict markers, and soft-delete tombstones.
- Added tests for UID profile identity, local visibility filtering, cross-owner write rejection, revisions/timestamps/tombstones, disabled sync/conflict behavior, and a version 1 to 2 migration.
- Remote synchronization is not implemented: no Firestore package/adapter, reads, writes, upload queue, or backend rule changes exist. Client-side ownership and visibility checks only reduce accidental local misuse; they are not a security boundary.
- The two-account allowlist functions remain undeployed. Firebase sign-in is not guaranteed to be restricted to Abdullah and Jannat.
- App-level database encryption and a local app-lock flow are not implemented. Given the intended personal records, evaluate app-level encryption with Keystore-backed key management before collecting real sensitive data if unlocked-device, backup, rooted-device, or storage-extraction risks are in scope. This remains separate from Firebase ownership/security rules.
- `dart format lib test`: passed after Phase 3 changes.
- `flutter analyze`: passed after Phase 3 changes.
- `flutter test`: 12 widget and database tests passed, including the version 1 to 2 migration.
- The local SQLite file is stored in the operating system's app support area. LIFE OS does not add database-level encryption in this phase.

### Focused Phase 3 data-layer hardening

- Repository public methods now obtain the active UID from a `CurrentUserIdentity` backed by `FirebaseAuth.currentUser`; callers no longer pass arbitrary viewer/actor UIDs. Unauthenticated calls fail closed, profile writes must match the current UID, and record writes/deletes are bound to it.
- Record streams follow Firebase auth-state UID changes, cancel the previous user's SQLite watch, stop stale emissions, and emit an unauthenticated error on sign-out. Tests cover switching users and sign-out while watching.
- Validate non-empty trimmed identifiers/profile names, JSON-object payloads, chronology, timezone labels, positive revisions, initial revision 1, expected update revision, and locally controlled sync metadata. Stored unknown kinds, visibility values, and sync states fail closed when decoded.
- Updates reject stale revisions/timestamps. Tombstone deletion is transactional and idempotent; tombstoned records cannot be edited back to life implicitly. Conflicted records block local edits/deletion until an explicit resolution flow exists.
- Conflict snapshots retain remote kind, visibility, payload, timestamps, timezone, revision, and deletion metadata. Matching snapshots clear conflict state; divergent snapshots remain marked conflict.
- Repository sync remains unconditionally disabled; local writes force `localOnly`. The remote-store interface is only a contract and has no implementation.
- Drift database ownership is scoped to a Riverpod provider container, which invokes asynchronous close on disposal. A provider lifecycle test verifies close is initiated.
- The SQLite file is in Android app-specific internal storage (`filesDir`). The manifest currently omits `allowBackup` and backup rules; Android Auto Backup defaults to enabled and includes most app-internal files, so the DB may be backed up to cloud/device transfer on eligible devices. Choose and test a backup/restore policy before real records are collected.
- Android's app sandbox limits access from other ordinary apps, and platform storage encryption depends on Android version/device configuration. Given the intended personal data, app-level database encryption is recommended before real sensitive records are collected if unlocked-device, backup, rooted-device, or storage-extraction risks are in scope. Key management, backup/recovery behavior, and an app-lock threat model are not implemented.
- At the Phase 3 hardening review, no schema change was required; the schema was version 2 and the version 1 to 2 migration passed. Phase 4 later added version 3 as documented above.
- Final Flutter test suite: 18 tests passed (12 data-layer tests and 6 existing widget tests), including auth UID switching/sign-out, unauthenticated access, malformed fields, ownership, tombstones, conflict transitions, provider close, and versioned migration.
