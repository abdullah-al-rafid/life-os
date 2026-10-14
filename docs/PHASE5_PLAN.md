# LIFE OS Phase 5 Implementation Proposal

Status: approved implementation plan; schema v4, prayer UI/local data flow, prayer notifications, fasting, sleep, workouts, and Home/Insights summaries are implemented. Manual Android notification checks remain.

Checkpoint reviewed: `e478d1fab582f54bd28d6d7e335cd073449b7a60`.

## Scope

Phase 5 adds local prayer tracking and reminders, date-specific fasting records, sleep-duration entries, and workout logs. It connects these records to Home and Insights. It does not add prayer-time calculation, location services, cloud sync, learning evidence, Screen Time, PDF/export, AI planning, or other later-phase functionality.

All data remains on-device and scoped to the current Firebase Auth UID. Shared visibility is explicit and defaults to private. Current local ownership and visibility checks reduce accidental cross-account access; they are not a security boundary. No remote writes are introduced.

## Existing project findings

- The reviewed HEAD matches the supplied checkpoint and `git status --short` was empty before this planning document was created.
- Drift schema version 3 contains UID-keyed `profiles`, typed-envelope `stored_records`, and append-only `activity_history`. Migrations already test v1-to-v3 and v2-to-v3 preservation.
- `LifeRecordKind` already includes `prayer` and `fasting`. `StoredRecords` supports private/shared visibility, revisions, timestamps, and tombstones. Repository access is bound to the current Auth UID.
- `activity_history` has a composite uniqueness constraint, but history queries join to `stored_records` by definition ID. It is designed for task/goal activity, not date-keyed, editable prayer/fasting/sleep/workout entries without an anchor definition.
- Riverpod providers live in `lib/features/records/presentation/record_providers.dart`. Planning UI and repository code are currently combined under `features/planning`; Home and Insights consume Riverpod streams. Navigation has Home, Plan, Goals, Insights, and Settings.
- Theme tokens and shared loading/empty/error widgets are in `lib/app/theme` and `lib/core/widgets`. The current test suite uses in-memory Drift fixtures; v1 and v2 migrations are covered.
- There is no local notification, timezone, prayer, fasting, sleep, or workout implementation or dependency yet.

## Proposed feature structure

```text
lib/features/prayer/
  domain/ prayer_models.dart, prayer_repository.dart, prayer_reminder_service.dart
  data/ drift_prayer_repository.dart, local_notification_service.dart
  presentation/ prayer_screen.dart, prayer_settings_screen.dart, prayer_providers.dart
lib/features/fasting/
  domain/ fasting_entry.dart, fasting_repository.dart
  data/ drift_fasting_repository.dart
  presentation/ fasting_screen.dart, fasting_providers.dart
lib/features/wellness/
  domain/ sleep_entry.dart, workout_entry.dart, wellness_repository.dart
  data/ drift_wellness_repository.dart
  presentation/ wellness_screen.dart, wellness_providers.dart
```

Keep common persistence and notification abstractions small. Do not move Phase 4 files as part of this phase. Add routes reachable from Home and the relevant feature cards; preserve the existing five primary navigation destinations unless usability testing shows another destination is needed.

## Proposed data model and migration

### Prayer schedule configuration

Keep the user’s default five-prayer schedule and reminder preferences in a versioned `LifeRecordKind.prayer` record in `stored_records`. Store five named prayer slots (Fajr, Dhuhr, Asr, Maghrib, Isha), Azan/Jamaat wall-clock minutes, an IANA timezone ID, reminder enabled state, interval, maximum reminder count, and channel preference. Keep the record private by default. Validate all five slots, minute ranges, and that Jamaat follows Azan for each slot.

When a schedule is changed, the next reminder calculation uses the new times. Existing prayer tracking entries keep snapshots of the scheduled times/timezone used for that date so history remains interpretable. Do not calculate universal prayer times or assume a city/method.

### Additive schema version 4

Add one `tracking_entries` table instead of forcing date-keyed wellness events through `activity_history`'s definition join. Suggested columns:

- `id` primary key; `owner_uid` foreign key to `profiles.auth_uid`.
- `kind`: `prayer`, `fasting`, `sleep`, or `workout`.
- `local_date` (`YYYY-MM-DD`) and stable `entry_key` (prayer name, `daily`, or workout ID).
- `visibility`, validated JSON `payload_json`, `created_at_utc_ms`, `updated_at_utc_ms`, `revision`, nullable `deleted_at_utc_ms`.
- Unique `(owner_uid, kind, local_date, entry_key)` and an index for `(owner_uid, local_date, kind)`.

Prayer payloads store completion status (`prayedOnTime`, `prayedLate`, or `missed`), optional Jamaat status (`jamaat`, `individual`, or unknown/unset), notes, and that day’s schedule snapshot. Absence of a row means unrecorded; it does not mean missed. Fasting entries are optional per day and use an explicit `fasted`/`notFasted` value with optional notes; absence means no entry, not a fasting day. Sleep stores duration minutes (1–1440) and notes, keyed to the local wake-up date. Enforce uniqueness by `(owner_uid, kind = sleep, local_date)` so each user has at most one sleep entry per local wake-up date; edits require the current revision. Workouts store activity, duration minutes, notes, and date; multiple workouts per day are allowed.

Use optimistic revisions for edits and tombstones for deletion. Keep history as separate dated entries; editing one date must not mutate any other date. Visibility is private by default. Validate the entry owner against the repository’s active UID on every operation and scope every stream/query by that UID.

The migration from v3 to v4 only creates this table and index. It must preserve profiles, record definitions, task history, revisions, and tombstones. Existing v1/v2 upgrades must still reach v4 by sequential migration. Do not read or rewrite the real database during development tests.

## Dependencies and Android configuration

Proposed direct Flutter dependencies:

- `flutter_local_notifications` for local notification channels, scheduling, cancellation, and action handling.
- `timezone` for explicit zoned schedules (`TZDateTime`); use it directly rather than relying on a transitive dependency.
- `flutter_timezone` to obtain the device’s current IANA timezone and detect timezone changes on resume.

Select compatible stable versions only during implementation after checking the project’s Flutter/Dart constraints and the current package setup guide. Do not add `permission_handler` unless the chosen plugin cannot expose the required notification permission APIs.

Android work likely includes notification channel setup and manifest declarations for `POST_NOTIFICATIONS` (requested at runtime on Android 13+), `RECEIVE_BOOT_COMPLETED`, and the plugin’s scheduled-notification/boot receivers. Android notification permission and exact-alarm access are separate concerns. If notification permission is denied, do not schedule or deliver notifications regardless of exact-alarm access. If notifications are allowed but exact-alarm access is unavailable, use inexact notifications and show the delay warning. Exact scheduling may require `SCHEDULE_EXACT_ALARM`; check its grant state before using exact alarms. Do not declare `USE_EXACT_ALARM` by default. The plugin version may require core library desugaring in `android/app/build.gradle.kts`; verify that requirement against the selected release before editing Gradle.

The plugin documentation notes that scheduled notifications need a boot receiver to restore schedules and recommends `zonedSchedule`; Android 14 denies exact-alarm access by default for many newly installed apps targeting Android 13+. See [flutter_local_notifications setup](https://pub.dev/packages/flutter_local_notifications) and [Android exact alarm guidance](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms). Android 13 notification permission behavior is described in [Android notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission).

## Notification behavior proposal

Implement a `PrayerReminderService` interface with a fake test implementation and a production notification adapter. Do not schedule reminders until the user enables them and grants notification permission. Create one respectful, user-configurable Android channel. Notification actions should support dismissing the current prayer’s remaining reminders, snoozing once, or disabling reminders; record suppression for the current local date so rescheduling does not revive dismissed reminders.

For each enabled prayer, schedule Azan and reminders every 5 minutes, up to a maximum of 6 reminders for that prayer session, stopping at Jamaat time. Skip times already elapsed and skip dismissed or completed prayers. Use stable notification IDs so marking a prayer complete immediately cancels that session’s remaining reminders. Changing its Jamaat time immediately reconciles the session and cancels or reschedules affected pending IDs. Other schedule edits likewise reconcile affected notifications before scheduling replacements. Do not promise exact delivery: Doze, force-stop, OEM battery controls, denied exact-alarm access, and denied notification permission can delay or suppress notifications.

On app startup/resume, permission changes, schedule edits, reminder-preference edits, and timezone/date changes, reconcile managed notification IDs against current local records. Follow the device’s current local timezone. A timezone change may reschedule future notifications, but must never silently rewrite historical local dates or saved schedule snapshots. Schedule a bounded future horizon and recompute it on foreground. Use the plugin’s boot receiver to restore scheduled notifications after reboot; document that force-stop and OEM restrictions may prevent delivery until the app is opened again. Never claim that a notification was delivered just because it was scheduled.

## Ordered implementation steps

1. Use the approved defaults recorded below: device-local timezone, five-minute reminders capped at six per prayer session and stopped at Jamaat or completion, inexact notifications with a delay warning when exact-alarm access is unavailable, separate notification-permission handling, and one sleep entry per user per local wake-up date. Inspect current package compatibility and Android manifest/Gradle setup without altering Firebase configuration.
2. Add schema v4 and generated Drift code. Add migration fixtures for v3-to-v4 and v1/v2-to-v4, asserting preservation of existing profile, record, history, revisions, and tombstone data.
3. Add shared tracking-entry validation and UID-bound repository interfaces/adapters. Test ownership, visibility, account switching, stale revisions, tombstones, malformed payloads, duplicate keys, and local-only sync status.
4. Implement prayer schedule settings and dated prayer status/logs; add five-prayer UI, schedule editor, status/note flows, loading/empty/error states, and private-by-default visibility.
5. Implement the notification gateway, permission onboarding, channel, stable ID strategy, scheduling reconciliation, cancellation/rescheduling, snooze/dismiss, boot recovery, timezone refresh, and exact/inexact fallback. Keep user permission prompts contextual and explicit.
6. Implement fasting daily records and history UI. Do not pre-populate fasting days or infer missed fasts.
7. Implement sleep and workouts with date selection, validation, edit/delete semantics, history, and basic summaries.
8. Add Home and Insights summary cards backed by real local streams; include empty/loading/error states and the existing local-only indicator.
9. Update README, implementation status, and decisions with implemented behavior, notification limitations, data migration, and remaining security limits. Run formatter, analyzer, full tests, and `git diff --check`.

## Acceptance criteria

### Prayer

- The UI displays exactly five named daily prayers and lets each authenticated user configure Azan/Jamaat times and timezone-aware reminders locally.
- Validated completion status, optional Jamaat status, and notes are saved for a chosen local date; missing entries remain unrecorded.
- Changing a schedule cancels stale pending reminders and schedules the new eligible times without changing prior prayer logs.
- Permission denied, exact-alarm unavailable, empty schedule, malformed schedule, save failure, and notification-scheduling failure produce clear states and a manual fallback.
- Account switching immediately removes the previous account’s schedule and logs from visible streams.

### Fasting

- A user can mark a specific date fasted or not fasted and add/edit notes; dates without records remain unrecorded.
- Duplicate daily records fail safely or update only through an explicit revision-checked edit; history is scoped to UID and selected date range.
- Home and Insights summaries use actual stored entries and do not count unrecorded dates as missed fasts.

### Sleep and workouts

- Sleep duration and notes validate and persist against the chosen local date; the summary reports only dates with records.
- Multiple workouts can be logged for one date with activity, duration, and notes.
- Edit, delete, stale revision, account switch, shared visibility, and local-only behavior follow the existing repository safeguards.

## Test plan

- Repository unit tests: required fields, date and time boundaries, timezone IDs, status enums, durations, JSON payloads, unique prayer/date and fasting/date keys, multiple workout entries, stale revisions, tombstones, and database failure mapping.
- Ownership/privacy tests: private records never appear for the other UID; explicitly shared records follow current visibility; account-switch streams stop old-user emissions; sign-out errors fail closed.
- Migration tests: v3-to-v4 and v1/v2-to-v4 preserve legacy rows and create the new structures; all use in-memory SQLite.
- Notification unit tests with a fake gateway/clock/timezone: no schedule without permission; stable IDs; update cancels old IDs; no past reminders; interval/count cap; Azan before Jamaat; snooze/dismiss; permission revocation; DST/timezone/date changes; boot/resume reconciliation; inexact fallback.
- Widget tests: prayer setup and schedule editor, permission-denied/manual mode, all prayer statuses, date selection, fasting empty/recorded states, sleep/workout validation and history, plus Home/Insights loading, empty, error, and populated summaries.
- Device/emulator manual checks: Android 13+ notification prompt, Android 12+ exact-alarm settings flow where supported, Android 14 fresh install denial behavior, reboot recovery, timezone change, daylight-saving boundary where available, force-stop limitation, notification channel settings, and battery-saver/Doze behavior. No manual test should use the user’s production database as a fixture.

## Risks and open product defaults

- **Timezone policy:** approved default is to follow the device’s current local timezone. Store the IANA timezone and per-entry schedule snapshot. A timezone change can reschedule future reminders, but historical local dates and snapshots remain unchanged.
- **Exact delivery:** exact alarms require user/system access on affected Android releases. Proposed fallback is inexact notifications with an explicit “timing may vary” indication; do not use alarm-clock-only permission by default.
- **Reminder volume:** approved defaults are a 5-minute interval and at most 6 reminders per prayer session, stopping at Jamaat or when the prayer is marked complete. Keep quiet/suppress per prayer, snooze once, and the separate notification channel controls.
- **Fasting meaning:** proposed statuses are only fasted/not fasted/unrecorded; avoid asking for reasons or recording health explanations unless requested.
- **Sleep model:** approved first version stores one total duration per user per local wake-up date, with revision-checked edits; it does not store sleep stages, devices, or multiple sleep sessions.
- **Sharing:** proposed default is private. Shared status must be a deliberate per-record action; local filtering does not secure data from a modified client.
- **Data protection:** SQLite remains unencrypted and Android backup policy remains unresolved. Phase 5 does not solve database encryption or backup retention.
- **Manual Android behavior:** emulators and OEM devices vary in exact alarms, battery restrictions, boot restoration, and notification permission behavior. Automated fake-gateway tests cannot prove delivery on every device.

## Implementation update

The local tracking foundation, prayer schedule/log UI, prayer notifications, fasting, sleep, workouts, and Home/Insights summaries have been implemented. The notification implementation uses `flutter_local_notifications` 22.3.2 and `timezone` 0.11.2, the existing Android timezone bridge, a seven-day reconciliation horizon, a private UID-scoped suppression record, separate notification and exact-alarm permission handling, inexact fallback with a delay warning, and Android boot recovery configuration. Historical local dates and schedule snapshots remain unchanged. Automated fake-gateway and local tracking coverage is in place; Android device/emulator permission, reboot, timezone, Doze, force-stop, and OEM delivery checks remain. No Firestore writes, cloud sync, Cloud Functions deployment, Firebase billing change, or server-side account enforcement was performed.

Stop for user review before continuing beyond the prayer notification milestone.
