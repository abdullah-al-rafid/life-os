# Architecture and Implementation Decisions

## 2026-10-14 — Audit baseline

- The repository is a generated Flutter application with no existing product architecture or LIFE OS feature code to preserve.
- Keep Android-first scope while avoiding premature platform-specific implementation. Platform support beyond Android should be decided feature by feature.
- Treat the requirements in `PROJECT_SPEC.md` as authoritative. The requested order is the baseline; implementation dependencies may justify documented reordering.
- No final state-management, routing, local database, synchronization, notification, evidence storage, or PDF package choices have been made. Select compatible maintained packages during the relevant implementation phase and record exact choices then.
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

## Open decisions

- Firebase project ownership, region, and account provisioning process for the two named users.
- Whether Firebase Storage is the selected private evidence backend, and its retention limits.
- Exact local timezone behavior for records when users travel or timezone settings change.
- Backup, retention, and deletion expectations for personal records and evidence.
- Whether the currently generated non-Android platform folders should remain supported long-term.
