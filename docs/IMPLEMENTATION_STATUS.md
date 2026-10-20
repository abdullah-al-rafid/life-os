# LIFE OS Implementation Status

Updated: 2026-10-20 (Asia/Dhaka)

## Current status

- Phase 0 (audit): Complete.
- Phase 1 (UI foundation): Complete.
- Phase 2 (authentication): App implementation complete; Firebase project activation and live integration verification are blocked on user setup.
- Phase 3 (offline data architecture): Local foundation implemented; remote synchronization remains disabled.
- Phase 4 (routines, tasks, goals, habits): Implemented with local-only persistence and tests.
- Phase 5: Local data foundation, prayer tracking and notifications, fasting, sleep, workouts, and Home/Insights integration implemented; this milestone awaits review. Device-level notification checks remain.
- Phase 6 (assigned-task remote projection): adapter, local default-deny rules, and emulator tests are present. The local Firestore Emulator suite passed 11/11 tests against `demo-life-os` with synthetic identities on 2026-10-20; production rules, membership state, and cross-device behavior remain unverified. General record sync remains disabled.
- Phase 7 (File-to-15-Day Task Planner): Local implementation and tests pass; import is directly reachable from Home and Plan. Actual file-picker behavior still needs device verification.
- Phase 8 (Learning and Private Evidence): local task-completion attachments are implemented as a limited first slice; full learning-session workflows and camera capture remain incomplete.
- Phase 9 (Android Screen Time): local Usage Access query and date-filter UI are implemented; device verification remains.
- Phase 11 (Reports/Export): local 15-day PDF preview/save/print/share and account-scoped JSON backup/restore are implemented and covered by tests; device-level export and restore review remains.
- Phase 12 (15-day Adaptive Planning): approval-only carryover proposal implemented as a partial slice; full adaptive analysis remains incomplete.

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

- General record synchronization remains disabled and local-only. A separate Firestore adapter exists for assigned tasks only; its UI feature flag defaults off, and production rules/membership state and cross-device behavior have not been verified from this workspace.
- Remaining-feature work: approval-only rolling carryover proposals, local task evidence, and Android Usage Access query/UI have partial implementations. Reports and local backup/export are implemented; secure cloud sync remains blocked as noted below.

### Rolling plan proposal slice (partial)

- Added an approval-only proposal screen that compares completed versus incomplete tasks from prior imported task plans, carries forward unfinished tasks into the next 15 local dates, balances estimated minutes across days, and warns when a day exceeds the selected capacity.
- The user can change the daily capacity, edit proposed titles, regenerate, and explicitly approve. Approval uses the existing UID-bound atomic task-plan import and receipt table; a stable per-user/per-cycle fingerprint prevents duplicate imports. Existing definitions and append-only history are left unchanged.
- The Home dashboard lists overdue one-time tasks first and displays each task's priority and estimated minutes.
- Home now shows the device-local date, every due/overdue item, any available target date, priority and estimated minutes, same-day completion status, and quick Done/Partial/Not Done actions. Completing an overdue one-time task records today's actual completion date while preserving its original scheduled date.
- Home provides direct 15-day import and Screen Time entry points, a local goals/shared-record summary, a current-day prayer summary, and existing fasting/wellness tracking summaries. Cards state that marked-shared records remain local while cloud sync is off. Plan cards label private versus shared-on-this-device visibility.
- This is not the complete adaptive planner: it does not yet analyze goal progress, deadlines, all routine commitments, or completion-rate trends; it does not expose full field editing or compare all previous plan versions. It carries forward tasks from prior imported plans only. No automatic activation or historical rewrite occurs.

### Learning evidence and Android Screen Time (partial)

- Task completion accepts up to five optional local evidence files from the gallery/file picker: JPEG, PNG, WebP, PDF, TXT, and DOCX, up to 10 MB each. Extensions and basic file signatures/text encoding are checked. Bytes are stored in the app-private support directory under the active Auth UID. Completion history keeps relative keys, names, sizes, and timestamps; evidence-bearing events are private even if their task is shared. A failed history write removes files written by that attempt.
- Selected image previews are shown before saving, and attachment names appear in local completion history. Evidence is not uploaded; Android cloud/device backup extraction rules exclude the evidence directory. The app does not explicitly disable Android Auto Backup, so the local SQLite database may be included in system backups; review this policy before storing real sensitive records. Direct camera capture, history-time file preview, explicit evidence retention UI, and evidence cleanup after task deletion are not implemented. Local evidence and the SQLite DB are not app-level encrypted.
- Android Screen Time uses a native `UsageStatsManager` bridge. It explains the special Usage Access setting, opens Android settings, checks authorization before querying, refreshes on resume, and groups foreground time by app for a chosen local date. Denied access and empty/unavailable data are shown distinctly. It is Android-only and has not been manually verified on a device/emulator. Usage summaries are queried on demand, not persisted.

### Remaining required features and blockers

- Learning sessions are not implemented. Evidence attachment support is limited to task completion and has no camera capture or history preview. No evidence is uploaded.
- Local 15-day PDF reports and account-scoped JSON backup/restore are implemented. The backup excludes evidence file contents and remote assigned tasks; it is not a complete device or cloud recovery system. Review restore behavior and exported personal data before relying on or sharing these files.
- Android Screen Time code is implemented, but Usage Access has not been granted or tested on device; no real usage output is claimed.
- General Cloud Sync remains disabled. The local `firestore.rules` and assigned-task adapter are present. The Firestore Emulator suite passed 11/11 tests against `demo-life-os` with synthetic identities on 2026-10-20; this does not establish deployed production rules, production membership, or live synchronization. Do not enable the assigned-task build flag or production writes until trusted identities/memberships and deployed rules are independently verified and live access tests pass.

### Audit verification (2026-10-20)

- Flutter 3.41.2 / Dart 3.11.0: `flutter analyze` passed with no issues; `flutter test` passed (153 tests); `flutter build apk --release` succeeded (76.2 MB APK).
- Cloud Functions allowlist tests: 3/3 passed with both direct Node execution and `npm test --prefix functions`.
- Firestore Rules emulator tests: 11/11 passed with Java 25 and the explicitly isolated `demo-life-os` project. The emulator used synthetic test identities; no production service was targeted.
- No device install, live Firebase authentication, production rules deployment, production membership provisioning, or cross-device synchronization test was performed.

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
- Prayer and fasting are implemented in Phase 5. Learning-session workflows, full evidence management, complete Screen Time verification, PDF/JSON reports, AI planning, cloud sync, and server-enforced allowlisting remain incomplete.

### Phase 5 first milestone: local tracking data foundation

- Increased the Drift schema to version 4 with an additive `tracking_entries` table for date-keyed prayer, fasting, sleep, and workout entries. Added partial unique indexes for active `(owner_uid, kind, local_date, entry_key)` values, the approved one-sleep-entry-per-owner/local-date rule, and owner/date/kind queries. Tombstoned keys may be recreated as new entries without restoring the old row.
- Added strict tracking-entry validation for IDs, owner UID, real local dates, UTC timestamp order, revision values, kind-specific payloads, five named prayer keys, prayer schedule snapshots, fasting statuses, sleep/workout durations, and required workout activity.
- Added an offline repository and Drift store bound to the current Auth UID. Streams switch/cancel on account changes; reads are owner-scoped or explicitly shared; only the owner may update/delete; writes use optimistic revisions and soft tombstones. No remote adapter or cloud write path was added.
- Preserved existing Phase 2/3/4 structures and behavior. Migrations from v1, v2, and v3 now reach v4 sequentially; the v3 fixture confirms profile-linked record payload/revision/tombstone and activity history preservation. All migration/repository tests use in-memory SQLite.
- Approved decisions reflected in the checklist: device-local timezone; 5-minute prayer reminders capped at 6 and stopped at Jamaat or completion; inexact notification with delay warning if exact-alarm access is unavailable; separate notification permission; one sleep entry per user per local wake-up date.
- This milestone does not implement prayer schedules/UI, notifications/permissions/channels, fasting/sleep/workout UI, Home/Insights integration, or dependencies. Those remain pending user review.

### Phase 7 File-to-15-Day Task Planner

- Added local import support for the supplied LIFE OS XLSX template and CSV, TXT, DOCX, and selectable-text PDF files. Extraction runs on-device; scanned/image-only PDFs, OCR, AI processing, and external file upload are not supported. The supplied template is included at `docs/templates/LIFE_OS_15_Day_Task_Import_Template.xlsx`.
- Deterministic brief extraction generates a complete 15-day set of review suggestions. Structured XLSX/CSV rows preserve their day assignments and support multiple tasks per day. Source sheet/row, paragraph, page, or text-line references are retained where available. Missing or ambiguous content, empty days, parser uncertainty, dependency errors, and daily-capacity overloads are reported for review.
- Added a complete 15-day preview with date/capacity controls, regeneration, per-task editing, add/remove, day reassignment, priorities, duration estimates, preferred times, dependencies, measurable completion criteria, source references, and explicit import approval. Plan navigation can select a date; Home/Insights expose upcoming imported-plan summaries.
- Imported tasks use the existing task records and are created as new records. Existing definitions and append-only completion history are not edited. A schema v5 receipt table provides per-UID idempotency by file fingerprint, start date, and parser version. The receipt and all task rows are written in one SQLite transaction; an import failure rolls back the entire batch. Duplicate approvals fail safely.
- File contents remain local and tasks default to private. No AI endpoint, file upload service, Firestore write, or cloud sync was added. PDF native extraction and file-picker device behavior still require Android device verification.

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
- Phase 6: Assigned-task Firestore projection exists behind a default-off flag. Production verification is outstanding; general sync is not implemented.
- Phase 7: File-to-15-Day Task Planner; local tests pass; platform file-picker behavior still needs device verification.
- Phase 8: Learning sessions and full private evidence lifecycle; task-completion attachments are a partial first slice.
- Phase 9: Android Screen Time is implemented locally; device verification and any history persistence remain.
- Phase 10: Shared progress, comparison, leaderboard, and analytics.
- Phase 11: Local PDF preview/save/print/share and JSON backup/restore are implemented and tested; manual device behavior and restore review remain.
- Phase 12: Approval-based rolling carryover exists as a partial proposal; goal/deadline/workload analysis and plan-version comparison remain.
- Phase 13: End-to-end, accessibility, performance, security, and release validation.

### Final master completion follow-through (2026-10-14)

- Improved Home and Plan discoverability for the existing local importer and clarified local-only sharing. Home shows all due items and exposes same-day completion actions; overdue completion is recorded on the completion date without moving the task's scheduled date.
- This update does not implement the remaining report/PDF/JSON workflow, complete adaptive analysis, full learning evidence lifecycle, or secure cloud sync. Screen Time and notification delivery still need real-device verification. The cloud-sync blocker remains the absence of administrator-verified trusted UIDs and reviewed/tested Firestore rules; remote writes remain disabled.

### Assigned-task Firestore security follow-through (2026-10-15)

- Added a separately gated Firestore task projection, self-only membership reads with reciprocal trusted-peer checks, default-deny rules, and emulator tests for assigned updates, private-data isolation, unapproved users, and forged ownership. General local records and evidence remain local; Screen Time upload is out of scope.
- Both real Auth identities and production memberships could not be verified from the local project context. Production writes remain off; emulator tests use synthetic identities only. The feature flag defaults to false.
- Emulator verification: `firebase emulators:exec --project demo-life-os --only firestore "npm --prefix security-tests test"` (4 passed). Flutter focused planning/tracking/usage tests passed (40); `flutter analyze` and `git diff --check` passed; debug APK built.
- Do not enable the sharing flag until a trusted administrator verifies both users in project `life-os-abdullah-jannat`, provisions reciprocal active `lifeOsMembers/{uid}` documents, reviews the emulator-tested rules, and deployment is separately approved. No production rules were deployed in this work.

### Real two-device Cloud Sync phase: preparation (2026-10-15)

- Identity setup remains unverified. The app uses Firebase email/password sign-in and has no account creation flow. No trusted administrator evidence, authenticated session, or Firebase Console inventory was available to establish which Auth identities belong to Abdullah and Jannat. No UID values are recorded here or shown in the UI. The configured project ID is local configuration only and does not prove project ownership or live project state.
- The only remote data slice remains explicitly assigned tasks behind `LIFE_OS_ENABLE_SHARED_TASKS`, whose default is false. This is a direct Firestore projection, not a durable offline outbox: no retry/idempotency queue, local remote-task cache, or conflict merge is implemented. Do not describe it as verified cross-device sync.
- Expanded emulator rule tests cover revoked-task access, deactivated membership, invalid date/duration/notes, forged timestamps, immutable owner, invalid recipient changes, and extra fields. Emulator results are synthetic-identity authorization evidence only; they do not establish deployed production rules or device behavior.
- Personal routines/tasks, private goals and contributions, prayer, fasting, wellness, completion history/evidence, Screen Time, and JSON backup remain local. Existing JSON backup/restore code and data format were not changed.
- Before any production rollout: a trusted administrator must verify both intended Auth accounts in the exact Firebase project and provision reciprocal membership; the owner must review and separately approve the exact rules deployment and production enablement. Current phase does neither. Other open decisions include the recipient-cache purge/revocation UX while offline, durable retry/idempotency/conflict policy before claiming offline-first sync, local database encryption and device backup retention, and whether non-approved users should be blocked at sign-in.

#### Safe two-device test plan (after separate rules review/deployment approval)

1. Use two physical Android installations and two already-provisioned test Auth accounts verified by an administrator against the intended Firebase project. Record only aliases A/B, device/app versions, and timestamps; never record passwords, emails, or raw UIDs.
2. Confirm the sharing flag remains off and each device can sign in/out and retains its own local tasks, routines, goals, prayer/wellness records, Screen Time behavior, and JSON export/preview/restore workflow. Do not restore over existing data; use a fresh test profile/install only if the owner has approved that setup.
3. After the exact production rules and reciprocal memberships have been separately approved and deployed, build a test-only app with assigned-task sharing enabled. A assigns one non-sensitive test task to B; verify B sees it and can update only status, while A sees that status update. Verify unrelated account C cannot read or write it and private local records never appear remotely.
4. Revoke the task and separately deactivate B membership; verify fresh reads/writes are denied. Note that already downloaded data cannot be recalled while B is offline; reconnect before checking app-side cache behavior. Stop if the implementation has no documented, tested cache purge behavior.
5. Exercise airplane mode/reconnect, repeated submission, app termination, and sign-out/account switch only after a durable retry/cache design exists. Verify no work queued under A is sent as B and no local record is deleted or relabeled. Current adapter lacks those guarantees, so this phase must not claim those checks passed.

### Current-state clarification (2026-10-15)

- The assigned-task Firestore adapter is separate from the Drift-backed personal record repository. General tasks, routines, goals, habits, completion history, prayer, fasting, wellness, evidence, and Screen Time remain local; Screen Time is queried on demand and is not uploaded.
- At the time of this earlier UI foundation checkpoint, the four emulator security tests and focused Flutter checks above were historical results and were not rerun during that work. The current 11-test emulator and Flutter results are recorded in “Audit verification (2026-10-20)” above. Emulator identities remain synthetic and do not verify production rules or two-phone behavior.
- Plan and report periods are 15 days. The application imports a user-prepared CSV/XLSX locally and requires review and explicit approval; it does not silently generate or replace plans with AI.

### App-wide UI foundation (initial)

- Added reusable scroll-safe page/header, task/status, privacy/source, workload/progress, and shared component tests under `lib/core/widgets/life_os_components.dart`. Empty states now scroll safely when a screen has little remaining height.
- Primary navigation now includes Home, Plan, Goals, Together, Progress, and Settings. Existing `/insights` and `/plan/assigned` paths remain; prayer, fasting, wellness, Screen Time, import, and rolling-plan routes remain accessible.
- Shared task cards/status controls now appear in Home and the assigned-task view; shared source labels appear in Plan, Prayer, Fasting, Wellness, Screen Time, and Together. Rolling proposals use the workload indicator. This is an incremental UI foundation, not a completed app-wide redesign. Repository and storage behavior are unchanged.

## Earlier verification results (historical phase checkpoint)

- `dart format lib test`: Phase 4 run recorded below.
- `flutter analyze`: Phase 4 run recorded below.
- `flutter test`: Phase 4 run recorded below.
- `npm test --prefix functions`: 3 allowlist unit tests passed.
- `node --check functions/index.js`: passed.
- Live Firebase sign-in: not run. The local Firestore Emulator result is recorded above. No account creation, auth-provider change, Cloud Functions deployment, or production security-rule deployment was performed.
- Android build: not run at that historical checkpoint. The current release APK build is recorded in “Audit verification (2026-10-20)” above. Android SDK licenses were reported accepted by `flutter doctor -v` during Firebase configuration verification.

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

The entries below are historical snapshots from the Phase 2/3 implementation dates. They describe the repository at that checkpoint; the current state is summarized at the top of this file and in “Current-state clarification.”

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
- The SQLite file is in Android app-specific internal storage (`filesDir`). The manifest configures full and data-extraction backup rules, but those rules exclude only the evidence directory; `allowBackup` is omitted, which defaults to enabled. The DB may therefore be included in cloud/device transfer backups on eligible devices. Choose and test a backup/restore policy before real records are collected.
- Android's app sandbox limits access from other ordinary apps, and platform storage encryption depends on Android version/device configuration. Given the intended personal data, app-level database encryption is recommended before real sensitive records are collected if unlocked-device, backup, rooted-device, or storage-extraction risks are in scope. Key management, backup/recovery behavior, and an app-lock threat model are not implemented.
- At the Phase 3 hardening review, no schema change was required; the schema was version 2 and the version 1 to 2 migration passed. Phase 4 later added version 3 as documented above.
- Final Flutter test suite: 18 tests passed (12 data-layer tests and 6 existing widget tests), including auth UID switching/sign-out, unauthenticated access, malformed fields, ownership, tombstones, conflict transitions, provider close, and versioned migration.
