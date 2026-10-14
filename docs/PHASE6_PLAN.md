# LIFE OS Phase 6 — Secure Cloud Sync and Two-Account Access Control

Status: planning only. No application code, Firebase configuration, rules, billing, dependencies, database, or commits were changed.

Reviewed checkpoint: `a82044b98d593943d7b926c0ee5d846101ab5e6a`.

## Goal and boundary

Add server-enforced access control and explicit, offline-first Firestore synchronization for the two intended LIFE OS users. Drift remains the app's local source of truth. A record is never uploaded until the server rules and emulator tests for its access model are accepted. The required File-to-15-Day Task Planner is Phase 7; Learning and Private Evidence is Phase 8. Both are planned below so their dependencies and privacy boundaries are clear, but neither is part of Phase 6 implementation.

The app's current local UID and visibility checks are useful safeguards, but they are not authorization boundaries. Only Firebase Authentication and server-side policy can protect remote data from a modified client. No project UID, email allowlist, project ID, or credential is assumed in this plan.

## Current project findings

- At the start of this planning turn, Git HEAD matched the supplied checkpoint and `docs/PHASE6_PLAN.md` was the sole existing untracked file; no other changes were present.
- Firebase email/password auth is implemented through `FirebaseAuthRepository`; routing observes Firebase Auth state. No client registration screen exists. App session persistence uses the Firebase SDK.
- `functions/index.js` already declares `beforeUserCreated` and `beforeUserSignedIn` Identity Platform blocking functions. They currently compare a normalized email against the deployment parameter `LIFE_OS_ALLOWED_EMAILS`; they are not reported as deployed. Email matching is not the final record authorization key and email may change.
- The repository has `firebase.json` entries for Functions and Flutter. It has no `.firebaserc`, `firestore.rules`, or `firestore.indexes.json` in the inspected workspace. Locally generated `lib/firebase_options.dart` and `android/app/google-services.json` exist and are ignored by Git; their values were not opened or reported. Presence of these files does not establish the active Firebase Console project's state.
- There is no Firestore client dependency or Firestore adapter in `pubspec.yaml` or the application data layer. No live Firestore database, deployed rules, or remote read/write behavior was verified.
- Drift schema v4 has UID-keyed profiles, versioned `stored_records`, append-only `activity_history`, and date-keyed `tracking_entries`. `stored_records` has revision, tombstone, and local sync-state columns. `tracking_entries` has revision/tombstone columns and uniqueness indexes but no sync-state fields. New local writes stay `localOnly`; synchronization throws `SyncNotEnabled`.
- Local record repositories bind reads/writes to the active Firebase UID, allow explicit shared reads, restrict mutations to the owner, and switch streams on auth changes. Those checks are client-side only. Prayer schedules and prayer entries default to private. Fasting, sleep, and workouts also default to private.
- Documentation records unresolved server-side two-account enforcement, lack of local database encryption, and an undecided database backup/restore policy. No production database was accessed for this planning work.
- The existing status file calls learning Phase 6. This plan resolves future numbering as Phase 6 Secure Cloud Sync, Phase 7 File-to-15-Day Task Planner, and Phase 8 Learning and Private Evidence. Subsequent planned milestones shift to Phases 9–13 as listed below. Updating the status/roadmap is deferred until implementation approval because this task is documentation-only for this plan.

## Recommended design

### 1. Two-account authentication and authorization

Use exact, administrator-verified Firebase Auth UIDs as the canonical account identifiers. Obtain them only after the two users' accounts are provisioned and verified in the intended Firebase project. Never derive a UID from an email, invent a UID, trust a client allowlist, or ship an authorization list as a security control in the Flutter app.

Use the following approved default controls:

1. **Firestore Security Rules are mandatory.** Every read/write rule must require an authenticated request, an approved UID, and the applicable record ownership/visibility conditions. A modified client must not be able to read or change protected data by bypassing app routing.
2. **Keep identity blocking conditional on the strict sign-in requirement.** Disable user-initiated account creation/deletion where supported and provision the two accounts administratively. Firestore Rules always enforce the trusted UID allowlist. Use Identity Platform blocking functions only if preventing unapproved accounts from signing in at all is a strict requirement; if selected, the existing functions must use trusted UID/custom-claim authorization rather than the current email allowlist. Keep UID/claim management outside the mobile client.

Firestore rules alone can safely deny data access to all non-allowlisted accounts, even if those accounts can still authenticate. If the product requirement is that an unapproved user cannot obtain an authenticated LIFE OS session at all, the `beforeUserSignedIn` blocking function is necessary; an authenticated route guard or a client-side UID list is only UX. Identity Platform and blocking functions are not needed merely to enforce Firestore document access. Cloud Functions are not otherwise required for a client-side Firestore sync adapter.

The existing blocking function currently uses email allowlisting. The Phase 6 default is Firestore UID allowlisting plus administrator-managed account provisioning; the blocking function is optional and, if strict sign-in denial is confirmed, will be converted to check a trusted UID allowlist or immutable server-managed claim. Treat email changes and deleted/recreated accounts as explicit administrator workflows. Never fall back to email comparison in Firestore Rules.

### 2. Firestore document model and visibility policy

Keep one deterministic remote document per local record, partitioned by immutable Auth UID. Proposed starting layout:

```text
users/{ownerUid}/records/{recordId}
users/{ownerUid}/activity/{activityId}
users/{ownerUid}/tracking/{trackingEntryId}
```

Fields should be typed and validated: `ownerUid`, `kind`, `visibility`, `payload` (map), local `revision`, stable `createdAt`, `updatedAt`, optional `timezoneId`, and `deletedAt` tombstone. Use a deterministic ID derived from the local row ID under the owner's path, not a new random ID per upload. Keep app-private metadata, credentials, and notification suppression state out of Firestore unless separately reviewed. Consider storing full typed payload maps rather than a JSON string so Rules can validate allowed fields and types.

Rules and query design must account for Firestore's all-or-nothing query authorization; rules are not filters. Use an owner query scoped under the caller's own UID path. For shared reads, choose and emulator-test one explicit design before implementation: a collection-group query constrained to `visibility == 'shared'` with rules that can prove the constraint and check that the caller and owner are each allowlisted; or a server-maintained shared projection. Do not issue an unbounded query and expect rules to hide private documents. Add required indexes only after emulator query tests identify them.

| Operation | Owner's private record | Owner's shared record | Other approved account |
|---|---|---|---|
| Read | Allowed | Allowed | Read only while explicitly shared |
| Create | Owner path and matching `ownerUid` only | Explicit owner action; default private | Denied |
| Update | Owner only | Owner only | Denied, even when shared |
| Delete | Owner tombstone only | Owner tombstone only | Denied |
| Change visibility | Owner may publish/unpublish deliberately | Owner may return it to private | Denied |

Shared means readable by the other approved account; it does not grant edit rights. A shared definition's activity/history sharing semantics must be specified per record kind rather than inferred from a shared parent. Private profiles, auth data, prayer schedules, notification preferences, and reminder suppression remain private. Never upload data merely because it is visible in the local UI.

Changing a record from shared to private revokes subsequent server reads but cannot retract information already viewed, copied, or retained on an offline device. On its next successful sync, the recipient client should hide and purge its cached copy of the owner's record after receiving the revocation. Do not cascade-delete the recipient's independently owned activity/completion history when a shared definition is unshared or removed; that history remains owned by and readable to its recorder under its own visibility policy. The UI and policy must not promise instantaneous revocation for an offline device. Deletion is a tombstone by the owner; it never deletes another account's independent record or history.

### 3. Offline-first sync architecture

Add a remote-store interface alongside the current local stores and a coordinator that binds to one authenticated UID at a time. Drift remains authoritative for UI reads and local writes. The remote adapter may use Firestore only after rule tests pass. Do not let screens write directly to Firestore.

Prefer a **transactional local outbox** so a local mutation and its upload intent are committed in the same SQLite transaction. Schema v4's `stored_records` contains sync markers, but `tracking_entries` and `activity_history` lack a durable sync queue; plan an additive schema v5 with an outbox/sync-state table keyed by `(ownerUid, entityType, entityId, localRevision)` and durable states such as pending, in-flight/lease, acknowledged, retryable failure, and conflict. Include attempt count and next-retry time, but do not store credentials or sensitive error payloads. An outbox operation must be idempotent and survive app termination. A separate remote cursor per UID may be added if it is required by the chosen pull protocol.

Local saves, edits, archives, visibility changes, history appends, and tombstone deletes enqueue work transactionally. Keep application IDs stable across retries. Remote pulls validate owner, type, payload, timestamps, visibility, and revision before applying to Drift. Convert remote timestamps deterministically and retain the local calendar dates and prayer schedule snapshots exactly as stored. Do not modify the current schema or local data during planning.

The app should query its own owner path plus the explicitly shared query, then merge both into the local database without changing ownership. Track `lastSuccessfulSyncAt`, pending count, and user-safe failure status locally. Do not present the app as synchronized until remote reads/writes and recovery have passed integration tests.

Prefer the explicit Drift outbox as the retry queue and decide whether to disable or tightly constrain Firestore SDK disk persistence. Running two independent durable offline queues can create duplicate/conflict behavior and account-switch leakage. If SDK persistence remains enabled, document its account-isolation and cache-clearing behavior and test it on Android. Treat the Drift database and any Firestore SDK cache as separate personal-data stores.

### 4. Revisions, concurrency, retries, and tombstones

- Keep local optimistic revision checks. Before writing, use a Firestore transaction to compare the remote base revision with the outbox operation's expected base revision.
- On success, write the deterministic document with `revision = remoteRevision + 1` and acknowledge only that exact local operation. If the same operation ID/revision is already present with identical content, treat the retry as success. Do not overwrite a higher or divergent remote revision.
- If two devices edit offline, preserve both snapshots and mark a conflict in Drift. Never silently use last-write-wins for goals, history, prayer logs, wellness entries, or routines. Provide an explicit compare/keep-local/keep-remote resolution that itself creates a new revision after the user chooses.
- Treat activity and goal-measurement history as immutable append-only documents with deterministic IDs. Resolve duplicate uploads by idempotent document IDs and reject changed content under an existing immutable history ID.
- Represent delete, archive, and unshare as owner-only revisioned tombstones/state changes. Do not hard-delete remotely during normal sync. A delayed older update must not revive a tombstoned row. Remote rules must prohibit hard delete from clients and preserve immutable owner identity.
- Retry transient network/server failures with bounded exponential backoff and jitter, foreground/resume and connectivity triggers, and a durable queue. Permission denied, revoked account, malformed data, and schema mismatch are not infinite-retry errors; surface a safe status and preserve the local row/outbox for resolution.
- Cancel/stop subscriptions and the old UID's worker immediately on sign-out or account switch. Never process a queued operation using the newly signed-in user's credentials. Each operation carries the original owner UID and is sent only when `currentUser.uid` still equals it. Keep the old user's local data and pending queue intact; do not relabel or upload it as the next user.

### 5. Migration, backup, and recovery

Schema v5 should be additive. Migrations from v1, v2, v3, and v4 must preserve all existing profiles, record payloads/revisions/timestamps/tombstones, activity-history rows, and tracking rows. Use in-memory fixtures; never use the real database as a test fixture. Existing local rows start as `localOnly` and are not uploaded automatically on upgrade.

Before first sync for a UID, show a review/consent step with counts and kinds to be uploaded, explain which items are private vs explicitly shared, and require the signed-in owner to opt in. Stage initial upload in bounded batches; mark each row/outbox operation acknowledged only after server confirmation. Keep data local if the user declines or an upload is interrupted. On resume, continue idempotently. If the same UID already has remote data, compare deterministic IDs/revisions and create conflicts for divergence; never silently replace either side.

Define recovery before collecting synced personal data:

- Keep a versioned export/import format with schema validation and a restore preview.
- Prefer an encrypted user-controlled backup using authenticated encryption and a passphrase/key recovery process that does not embed keys in the app or source tree. Document that losing the recovery key can make that backup unrecoverable.
- Do not treat Firestore as the only backup. Evaluate Firestore scheduled backups/PITR and their billing before relying on them; keep retention/deletion behavior explicit.
- Test restore into an isolated database and a test Firebase project/emulator. Verify tombstones, ownership, sharing state, date/timezone snapshots, and revisions after restore. Never test restore against production data.
- Define account deletion, data export, remote deletion/tombstone retention, and local cache disposal procedures. A logout must not delete a user's records.

### 6. Security controls

- **Rules first:** default deny all collections; require an allowlisted authenticated UID, path/field ownership equality, known record kinds, valid visibility, allowed field keys/types, bounded payload sizes, valid revision progression, immutable `ownerUid`, and owner-only writes. Validate creates, updates, and tombstones separately. Ensure no broad recursive allow rule overrides a specific denial.
- **Rules do not filter:** every owner/shared query must be provably authorized by its query constraints and tested. Server/Admin SDK operations bypass Firestore Rules and require least-privilege IAM and independent authorization tests.
- **App Check:** consider Play Integrity App Check for Android and appropriate attestation for any supported platforms. App Check is defense-in-depth against unauthorized app clients, not user identity or record authorization. Register and observe legitimate app traffic before enforcing; use the debug provider only in isolated development/test builds. App Check has no-cost service status subject to provider quotas/limits, which can change.
- **Authentication:** keep password reset generic, no public registration route, and no credentials in logs. Add clear handling for the server-denied sign-in state. Do not place Admin SDK service-account keys in the Flutter bundle, Firebase client configuration, Git, or local export. The existing FlutterFire client config is not an Admin credential; keep generated local config ignored.
- **Local at-rest security:** SQLite currently has no app-level encryption and Android backup behavior remains unresolved. Before remote sync of personal data, decide whether to encrypt Drift (with an actively maintained SQLCipher-compatible solution), manage its key through Android Keystore, exclude the raw DB/key from automatic backups, and specify secure export/recovery. Keystore-bound keys may not migrate to a new device; design recovery separately. Encryption does not replace Firebase Rules.
- **Data minimization:** synchronize only approved fields. Keep auth secrets, passwords, private notification state, unnecessary device identifiers, and sensitive diagnostic text out of records/logs.
- **Abuse monitoring:** enable appropriate Authentication/Firestore/App Check metrics and alerts. Never log full record payloads, ID tokens, passwords, or personal notes.

### 7. Billing and deployment expectations

No billing change is part of this plan. Current official pricing documentation states that Firestore has a no-cost quota for one qualifying database (currently 1 GiB stored, 50,000 document reads/day, 20,000 writes/day, 20,000 deletes/day, and 10 GiB outbound transfer/month); usage and rates vary by region and can change. Several features including backups, point-in-time recovery (PITR), restore, TTL deletes, and extra databases require billing. Two accounts are likely to fit ordinary free quotas, but polling frequency, retries, history size, shared queries, backups, and region determine real cost; do not promise zero cost.

Cloud Functions for Firebase require the Blaze pay-as-you-go plan and a linked Cloud Billing account, even though usage has documented no-cost quotas and deployments can incur artifact/storage costs. The current `beforeUserCreated` / `beforeUserSignedIn` functions therefore require Identity Platform plus a billing-enabled deployment path. Identity Platform pricing currently documents a free tier for email users up to its stated monthly-active-user allowance; verify the applicable region/plan at approval time. A client-only Firestore sync adapter does not itself require Cloud Functions. Firestore and Firebase App Check may be usable within no-cost quotas, but billing plan and feature requirements must be rechecked before production.

Before any enablement, prepare a cost worksheet using the chosen region, expected local records, queries, sync interval, retry load, index/storage overhead, export/backup policy, and Identity Platform/Functions needs. Add budget alerts and usage dashboards if Blaze is approved. Budget alerts are not a guarantee of a hard spending cap.

Official references checked for this plan:

- [Firestore Security Rules overview](https://firebase.google.com/docs/firestore/security/overview)
- [Firestore rules conditions and authorization](https://firebase.google.com/docs/firestore/security/rules-conditions)
- [Secure Firestore queries](https://firebase.google.com/docs/firestore/security/rules-query)
- [Test Firestore Security Rules with the Emulator](https://firebase.google.com/docs/firestore/security/test-rules-emulator)
- [Identity Platform blocking functions](https://firebase.google.com/docs/functions/auth-blocking-events)
- [Firebase Authentication account actions and user management](https://firebase.google.com/docs/auth/users)
- [Firebase pricing plans](https://firebase.google.com/docs/projects/billing/firebase-pricing-plans)
- [Firestore pricing and free quota](https://firebase.google.com/docs/firestore/pricing)
- [Identity Platform pricing](https://cloud.google.com/identity-platform/pricing)
- [App Check for Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)

Check these live sources again before implementation or billing decisions.

## Testing plan

### Rules emulator suite

Use synthetic UID fixtures (A, B, and unapproved C) in the Firestore Emulator. No production account, password, UID, database, or Firebase project is a test fixture. Test both direct document operations and production-shaped queries.

- Unauthenticated requests denied for every collection and query.
- Unapproved authenticated UID C denied all reads and writes, including profile, owner path, shared path, queries, and malformed paths.
- A and B can each read/write only their own private records; each is denied the other's private reads/writes.
- A and B can read the other's explicitly shared records; both are denied editing/deleting the other's shared record.
- Owner-only share/unshare transitions; changing `ownerUid`, ID, immutable creation metadata, or type is denied.
- Reject arbitrary visibility values, unknown kinds, missing/extra forbidden fields, oversized/malformed payloads, invalid dates/timestamps/revisions, client hard deletes, stale revisions, and tombstone resurrection.
- Query tests prove private owner queries and shared queries are constrained; an unfiltered query fails rather than silently leaking/filtering documents.
- Verify default-deny behavior on unmatched paths and guard against overlapping rules.

Firebase Rules tests must use client SDK contexts because Admin SDK and emulator fixture setup bypass Rules. Keep a small manually reviewed rules test matrix as a release blocker.

### Local migration, repository, and sync tests

- In-memory migrations v1/v2/v3/v4 to v5 preserve all rows and metadata; interrupted migration rolls back safely.
- Repository/outbox writes are transactionally atomic: no local mutation without outbox work and no outbox work without its local mutation.
- Private/shared routing, owner-only mutations, Auth UID changes, sign-out during an in-flight request, and pending work for another UID remain isolated.
- Idempotent duplicate upload/retry, duplicate history event, server timeout after commit, process restart, partial batch completion, backoff, permission denial, malformed remote data, and server schema version mismatch.
- Concurrent same-record edits from two devices produce a preserved conflict; resolution creates a fresh revision. Stale retries cannot overwrite higher remote revisions.
- Tombstone delivery before/after older updates, delete while offline, archive/unarchive policy, unshare while recipient is offline, and cache eviction after reconnect.
- Initial migration opt-in, remote empty/nonempty states, owner re-install, restore preview, interrupted restore, and export/import preserve IDs, dates, timezones, ownership, revision, sharing, and tombstones.
- Use emulator/test projects and fake remotes only. Add no production-write test.

### App/device integration

- Two authorized test accounts plus one unapproved account: verify auth gate, Firestore denials, owner/shared reads, and cross-device reconciliation.
- Android offline write/restart/online sync, airplane-mode sign-out/switch, app process kill during upload, and app data restoration.
- App Check debug provider in local emulator tests; verify Play Integrity on a supported test build before enforcement. Monitor metrics before production enforcement.
- Confirm no ID tokens, passwords, service-account credentials, record payloads, or local DB files appear in logs/artifacts.

### Phase 6 acceptance criteria

- The two real account UIDs are obtained from an authorized administrator and stored only in server-side policy/configuration. No UID/email allowlist in the client is treated as authorization.
- Emulator rules tests pass for all unauthenticated, unapproved, owner-private, shared-read, owner-write, query, tombstone, and malformed-document cases before the adapter can perform a remote write.
- Remote state is inaccessible to an unapproved account even when it bypasses the app UI. Only an owner can mutate their records; cross-account shared access is explicitly read-only.
- Local Drift remains usable offline. A restart-safe outbox, retries and idempotency do not duplicate or lose work; stale edits create preserved conflicts; tombstones cannot be resurrected by delayed retries.
- UID switches cancel the prior sync worker and cannot send or display another user's private data. Shared revocation hides/removes cached copies after reconnect without deleting the other user's independently owned history.
- Existing v1–v4 data migrates additively and remains local until the signed-in owner reviews the preview and opts in. No historical private bulk upload happens during upgrade.
- Backup, local encryption, retention, account deletion, App Check and cost controls have explicit reviewed settings before production sync. Automatic cloud backup and billing remain off unless separately authorized.
- Rollback/kill switch stops remote writes while preserving local data and queued operations. The app reports local-only, pending, conflict and sync error states truthfully.

## Phase 7 — File-to-15-Day Task Planner (required)

This is a required LIFE OS capability. It follows Phase 6 in the roadmap but is designed to work entirely offline and does not depend on Cloud Sync. Never upload a selected source file as part of first sync.

### End-to-end workflow

1. User selects a local source file and a start date. The picker initially advertises the prepared `LIFE_OS_15_Day_Task_Import_Template.xlsx` format. A workspace search at this checkpoint did not find that template; implementation must obtain the user's actual template and inspect its sheets/headers before defining a parser. Do not create a substitute and call it the supplied template.
2. Validate extension, file signature/container, file size, workbook/sheet count, text/page count, and parser limits. Keep the source in app-private temporary storage only as long as needed. Reject unsupported, encrypted, malformed, empty, oversized, or unreadable inputs with a clear recoverable message; do not partially import.
3. Extract text and structured rows locally into a normalized `SourceSection`/`SourceTaskCandidate` representation. Preserve source reference (file name, worksheet and row/cell, section/heading, or PDF page) and extraction warnings for each candidate.
4. Present extracted requirements for user review. Ask for missing planning constraints: 15-day start date, daily available minutes and availability by day, deadline, existing fixed commitments not represented in LIFE OS, and whether existing LIFE OS tasks should be included in capacity calculations. Show known existing tasks/routines for the window.
5. Run deterministic local extraction/normalization and scheduling as one operation. Generate a complete Day 1 through Day 15 view with one or more actionable tasks each day when the source supports a defensible schedule. If source content is insufficient to populate a day without inventing requirements, mark the gap, explain what is missing, and require user edits/confirmation before approval rather than fabricating material.
6. Validate and display all 15 days together. Show task details, duration, priority, category, dependencies, measurable completion criteria where relevant, source reference/confidence, per-day planned load versus capacity, total load, due-date feasibility, duplicate warnings, unresolved dependencies, and assumptions. Highlight ambiguity and unrealistic workload; do not mark an infeasible plan as valid.
7. Let the user edit any proposed task/date/estimate/dependency/criterion, move tasks, and regenerate all or selected days. Regeneration must preserve explicit user edits or clearly ask whether they will be replaced. Keep the source-derived draft distinct from committed task records.
8. Require an explicit final approval action naming the number of tasks and date range. In one local database transaction, create the complete task batch and its import ledger entry. If any validation or write fails, roll back the whole batch. The approved tasks use the existing task repository and become visible on their correct dates in Plan, Home, and Insights. Do not modify earlier tasks or completion snapshots.
9. Record an import receipt with source digest, parser/schema version, owner UID, date window, task IDs, and import timestamp. On a repeated matching import, open the prior receipt and prevent accidental duplicate task creation. Any intentional second copy must require a separate explicit confirmation and a distinct receipt; it never replaces tasks or erases completion history.
10. Remove temporary source bytes after the session unless the user explicitly chooses a separately designed local source archive. Store extracted source references and generated task provenance, not source contents, by default.

### Supported formats and order

Implement local deterministic support in this practical order:

1. **XLSX supplied template.** Parse the exact approved workbook and documented sheets/headers. Reject unsupported formulas or report when only cached formula values are available. Validate duplicate/missing headers, blank required cells, merged/hidden ranges if material, and Excel date/time values. Preserve sheet/row/cell references. The file is not currently present in this project workspace, so obtaining and reviewing it is an implementation prerequisite.
2. **CSV.** Use the same canonical columns and validation rules as the template; support quoted values, UTF-8 BOM, common delimiters/line endings, and a downloadable/importable example template. Preserve row numbers. CSV is easy to validate and test and provides a reliable text-table fallback.
3. **TXT.** Support plain UTF-8 text with headings, checkboxes, numbered lists, and explicit day labels. Preserve line numbers/headings. Require confirmation when segmentation or due dates are ambiguous.
4. **DOCX.** Extract paragraphs and headings with local-only OOXML parsing. Preserve heading hierarchy and paragraph position. Embedded images, tracked changes, tables, and complex layouts need explicit tested support or warnings; do not silently omit them.
5. **Text-based PDF.** Extract selectable text page by page with page references. Detect empty/scanned pages and report them as unsupported in v1. PDF layout order, columns, tables, and footnotes can be ambiguous; include an extraction preview and source confidence.
6. **Scanned PDF/OCR, encrypted files, and unusual workbook features** remain unsupported until separately reviewed. Do not silently invoke online OCR. OCR can be a later opt-in extension with local-processing/privacy evaluation.

Candidate dependency categories for implementation review are a file-picker, a maintained XLSX reader, a CSV parser, a ZIP/XML or dedicated DOCX text parser, and an on-device PDF text extractor. Select compatible stable packages only after checking current Dart/Flutter constraints, platform support, licenses, maintenance, archive safety, memory use, and extraction behavior against fixtures. Avoid bundling multiple overlapping document suites. Keep parsing behind `SourceFileParser` interfaces so an unsupported/poor package can be replaced without coupling it to task scheduling. No dependency is selected or installed during this plan.

### Source extraction and scheduling model

Normalize each extracted task to:

- required actionable title and source reference;
- optional description/notes, category, estimated duration, priority, explicit due date, and measurable completion criterion;
- explicit predecessor/dependency references where present;
- provenance and extraction state: direct structured field, deterministic text extraction, user-confirmed interpretation, or unresolved ambiguity.

Do not infer essential objective, audience, grading criteria, task dependencies, or deadline when missing. Ask for the missing information or label a suggestion as a user-editable assumption. Never present AI-created details as source facts.

Use a deterministic local scheduler first. Inputs include the 15 calendar dates, per-day available minutes, the user's existing commitments and recurring routine load, task estimate/priority/dependencies/deadlines, and any unavailable days. Constraints: tasks stay within Day 1–15 and deadline; dependencies precede dependents; daily minutes do not exceed user capacity unless the preview clearly identifies a user-approved overload; estimates are positive and bounded; multiple tasks may share a day. Prioritize explicit deadline and dependency constraints before priority and load balance. Provide reasons for each assignment and warnings for unscheduled/under-specified requirements. Re-running with identical source, constraints, and engine version should produce the same draft absent user edits.

The current `PlanningItem` already carries title, description, category, priority, scheduled date/time, duration, recurrence, and goal fields. Measurable task completion criterion is not a first-class field today; propose an optional backward-compatible `completionCriterion` payload field and validation/UI addition. Do not require a Drift migration for that payload-only addition unless inspection proves otherwise. A small additive Drift `plan_imports` ledger (proposed schema v6 after Phase 6's v5 sync outbox) is recommended for durable duplicate detection and atomic task/receipt writes. If the Phase 6 outbox design includes equivalent import idempotency records, reuse it instead of adding a duplicate table. The import batch and all created tasks must commit in one Drift transaction.

### Deterministic parsing versus optional AI

- **Phase 7 minimum:** deterministic template/CSV mapping and local text heuristics with human review. This is reproducible, private, offline, low cost, testable, and appropriate for the approved workbook. Heuristics should extract, not invent.
- **Optional future AI-assisted extraction/scheduling:** improves interpretation of prose but adds hallucination, privacy, connectivity, and recurring cost risks. It is not required for Phase 7 acceptance. Any AI path requires an explicit design review and consent on each external-processing mode before sending content.
- Do not embed model/provider API secrets in Flutter, Firebase client config, XLSX, or source control. A production AI integration needs a trusted backend with authentication, server-side authorization, quotas/rate limits, payload minimization/redaction, secret management, retention/deletion policy, safety validation, budget alarms, and a clear no-upload/local-only fallback. The service provider, region, data use/retention, latency, availability, billing, and minors/personal-data implications must be reviewed before approval.
- If AI is later approved, show the user which source text will leave the device, the destination/provider and retention statement, and require explicit consent. The AI result remains a draft; deterministic validation and user approval are still mandatory. Do not send source files or private data to external services by default.

### Phase 7 acceptance criteria

- Imports the actual approved XLSX template, with a validated schema version and source references, or reports exactly why the chosen file cannot be read.
- Parses CSV, TXT, DOCX, and text-based PDF in their approved implementation increments; unsupported/encrypted/scanned/empty/malformed files produce clear actionable states and no writes.
- Produces one preview containing all 15 days and multiple tasks per day when justified by source content. Each task has actionable title, description, category, priority, duration, target date, dependencies where present, and measurable criterion when appropriate.
- Uses supplied availability, known current commitments, dependencies, and deadline; calculates and displays workload overages and unrealistic scope. It never silently invents a source requirement or claims a constraint was met when it was not.
- Preview supports edit, regenerate, and approve. No task is persisted before explicit approval.
- Approved import creates all tasks and its receipt atomically in the current user's local DB; a failure creates none. Tasks appear on correct Plan/Home/Insights dates.
- Duplicate source/window imports are detected. Explicitly creating a second copy is deliberate and cannot overwrite tasks or completion history.
- Account switching isolates drafts/import receipts and never assigns imported tasks to a different UID. Parsing and scheduling work offline and make no network requests.
- Historical task definitions and completion/progress snapshots are unchanged by import or regeneration.

### Phase 7 test plan

- Golden fixtures for the actual workbook (once supplied), multiple sheets, reordered/missing/duplicate headers, blank rows, date serials, formulas, UTF-8/BOM CSV, delimiters/quotes, TXT headings/checklists, DOCX headings/tables, multi-column PDFs, scanned/empty/encrypted/large/corrupt files, zip bombs, invalid extensions, and parser resource limits.
- Source traceability tests prove every extracted proposal maps to a worksheet cell/row, CSV row, text line/heading, DOCX heading/paragraph, or PDF page; ambiguous/unmapped content triggers a warning.
- Scheduler tests cover all 15 days, capacity exactly at/over/under limit, multiple tasks/day, dependencies, deadline before/end/after window, unavailable days, existing scheduled/recurring commitments, equal priorities, missing estimates, unrealistic source scope, deterministic regeneration, and no invented tasks.
- Validation tests cover blank titles, invalid categories/priorities/durations/dates, self/cyclic/missing dependencies, duplicate fingerprints, duplicate task rows, missing completion criteria when required by a source format, and unresolved fields.
- Preview widget tests cover progress/loading, malformed/empty/unreadable errors, source uncertainty, workload warnings, all 15 day panels, edit/reorder/regenerate, explicit approval, cancel/no-write, and accessibility labels.
- Repository tests verify owner-scoped import receipts, account switching, duplicate import detection, explicit deliberate duplicate, concurrent/stale plans, atomic batch rollback under injected failure, and preservation of preexisting definitions and activity history.
- Migration tests for v5-to-v6 (and sequential supported upgrades) preserve v1-v5 records/tombstones/history and create the import ledger/indexes. Use in-memory DB fixtures only.
- Offline tests assert import performs no Firebase/HTTP calls and temporary source bytes are removed after completion/cancel/failure.

## Phase 8 — Learning and Private Evidence

After the task planner, add learning-session tracking and evidence metadata/files as a distinct phase. Reuse approved local task/import links and per-user ownership. Evidence is private by default and must not become shareable or remote merely because its task came from an imported plan. Define local file encryption, storage lifetime, backup exclusion, size/type validation, and explicit owner sharing before implementation. Remote evidence upload requires its own Firestore/Storage Rules tests, consent, cost/retention analysis, and Phase 6 security gates; do not infer that record sync authorization automatically secures Storage objects.

Acceptance: user can record a learning session against a task, attach only allowed local evidence metadata/files under size/type limits, review/delete it, and view dated history; tests prove account isolation, no accidental upload, retention/deletion, and migration safety. Evidence upload is not part of the Phase 6/7 plan and remains gated by a separate approved design.

## Sequential roadmap after the current checkpoint

| Phase | Milestone | Dependency and exit gate |
|---|---|---|
| 6 | Secure Cloud Sync and Two-Account Access Control | Approved UIDs/privacy model; rules emulator suite passes before any remote write; local-only remains functional; tested outbox/conflict/recovery; separate deployment approval. |
| 7 | File-to-15-Day Task Planner | Existing Phase 4 task repository; supplied XLSX template reviewed; fully local parsing/scheduling, preview, atomic import, dedupe and historical preservation pass. Does not technically require cloud sync but follows Phase 6 in the approved numbering. |
| 8 | Learning and Private Evidence | Phase 7 task linking and separate evidence privacy/storage design; no upload before Storage/rules and consent approval. |
| 9 | Android Screen Time Collection | Android permissions/usage access, date handling, privacy and local storage tests. |
| 10 | Shared Progress, Comparison and Analytics | Phase 6 server rules and explicit shared-data policies; never client-only authorization. |
| 11 | Reports, PDF Preview and Export | Accurate local/synced state, private export path, data-minimizing report/export tests. |
| 12 | Approval-Based Adaptive Planning | User review and consent for every generated plan; no automatic destructive changes. |
| 13 | End-to-End, Accessibility, Performance, Security and Release Validation | All feature phases complete; emulator/rules tests, device tests, privacy, recovery, accessibility, and release gates pass. |

The status file's current “Phase 6 Learning sessions” entry is acknowledged as superseded by this proposed numbering; revise it only when this roadmap receives approval. Phase 9–13 titles are proposed sequence labels, not implementation authorization.

## Ordered phases and rollout gates

1. **Project and account inventory (read-only).** Confirm Firebase project ownership and active project alias, current Auth providers and users, whether Identity Platform is enabled, existing Firestore database/data/rules, region, billing plan, current deployed Functions, and account provisioning authority. Do not print secret/config values. Obtain two account UIDs through a trusted administrator; never assume them.
2. **Threat model and remaining policy inputs.** Implement the approved UID allowlist, private-by-default/read-only sharing, explicit first-sync opt-in, conflict/tombstone rules, and no automatic backup. Obtain the actual UIDs; confirm whether sign-in itself must be blocked; decide which data kinds are eligible for explicit sharing and the local encryption, backup, and retention approach.
3. **Rules first.** Author least-privilege, default-deny Firestore rules and indexes in repository files. Build emulator tests and run the entire negative/positive matrix. Verify the actual Firebase project and deployed rules through a read-only check. Do not add a remote adapter or enable client writes in this step.
4. **Controlled security deployment.** Review the compiled rules and test results with the owner. Deploy reviewed rules before any client can write. Validate fail-closed behavior, admin IAM, backup/cost setting, App Check monitoring, and account creation restriction. No production deployment occurs as part of this plan.
5. **Sync schema and adapter behind a disabled feature flag.** Add additive v5 outbox and remote adapter contracts. Keep the adapter disabled by default; test all local migrations, retries, conflicts, account switching, and rules against emulators. No automatic initial upload.
6. **User-approved data migration.** On a test project, present per-account data inventory and explicit upload consent. Migrate one synthetic/test account, then test the second, shared visibility, conflict repair, export/restore, and deletion. Validate server state and client-local state without using a production DB fixture.
7. **Limited production rollout after separate approval.** Confirm both intended users, rules deployment, App Check readiness, backup/recovery, budget monitoring, and rollback procedure. Enable remote reads first for one opted-in account, then controlled writes, then the second account. Keep a global kill switch that stops remote writes while retaining all local data/outbox entries.
8. **Review and closeout.** Update README, decisions, implementation status, and roadmap numbering with exact deployed rules, implemented sync behavior, tested limitations, manual checks, billing configuration, and any unresolved risks. Wait for review before the next phase.

At every gate, local-only mode remains available. A rules or sync failure must never trigger a destructive local reset, silent conflict overwrite, or automatic change of record owner.

## Approved planning defaults and remaining decisions

The following requested defaults are incorporated into the plan and are not open questions for this planning document:

- Firestore Security Rules enforce a server-side allowlist of two trusted, administrator-verified UIDs. Client-side checks are defense-in-depth only.
- Identity Platform blocking functions are used only if blocking sign-in itself is a strict requirement; they are not required merely to secure Firestore data.
- Records are private by default. Other-account reads require explicit sharing; only the owner can edit or tombstone a record. Shared activity keeps its actual recorder/owner UID.
- First sync requires explicit per-account opt-in and an upload preview. No historical private records are uploaded automatically.
- Sync uses revisions, idempotent retry, durable tombstones, preserved conflicts, and no silent overwrite.
- Unsharing revokes future remote reads; cached copies are removed after the recipient reconnects. It never deletes the recipient's independently owned history. Deletion is owner-only and does not cascade across owners.
- SQLite encryption and backup/restore are separate security decisions. Automatic cloud backup is not enabled by this plan.
- Billing is neither enabled nor changed. Usage/cost controls are evaluated before any deployment.
- The sequence is Phase 6 Sync, Phase 7 File-to-15-Day Planner, Phase 8 Learning/Evidence, followed by Phases 9–13 in the roadmap table.

The following information/choices remain necessary at the relevant implementation gates; they do not block planning:

1. Trusted administrator supplies/verifies the two real Firebase Auth UIDs and confirms project ownership, project alias, account state, auth provider, Identity Platform status, Firestore state/region, deployed rules/functions, and billing plan. No identifiers are assumed in this document.
2. Confirm whether sign-in itself must be blocked for non-allowlisted Auth users. Default: Firestore Rules deny all their app data; use Identity Platform blocking only if strict sign-in denial is required.
3. Select exact record kinds eligible for sharing. Default: private for all; enable sharing only after per-kind review. Prayer schedules, notification preferences, and evidence remain private unless separately approved.
4. Decide local SQLite encryption/key recovery and backup retention before real cloud sync. Default: no automatic backup; no remote sync until the raw DB backup policy is known.
5. Confirm acceptable Firebase region and budget exposure before Blaze/Functions, paid backup/PITR, or over-quota use. Budget alerts are recommended but are not a hard stop.
6. Select production App Check providers/platform coverage and enforcement date after telemetry/metrics review. Keep App Check off or in monitoring mode for development until configured and tested.
7. Provide the actual `LIFE_OS_15_Day_Task_Import_Template.xlsx` for header/sheet review; it was not found in the workspace at this checkpoint. Confirm the default daily capacity input and whether users can supply unavailable-day/commitment data beyond existing LIFE OS tasks.
8. Confirm whether later AI-assisted planning may be explored. Default: deterministic on-device extraction/scheduling only; no external processing unless a separate privacy, backend, retention, consent, and cost design is approved.

## Risks and limits

- Firestore Rules can be correct while client queries are rejected if query constraints do not prove authorization. Shared reads are more complex than owner-only paths.
- A compromised approved account can access its own data and any data explicitly shared with it; two-account allowlisting does not replace account security or optional MFA.
- Shared information already downloaded cannot be recalled from a recipient who remains offline or copied it elsewhere.
- Local DB encryption and backup recovery may require a user-managed recovery key and may make forgotten-key backups unrecoverable.
- Firestore and Functions/App Check usage and pricing can change. The free quota is not a hard spend cap; backups/PITR and Functions deployment have billing requirements.
- Existing server-side allowlist code is email-based and undeployed per project documentation. Until a tested server-side restriction is enabled, arbitrary accounts may authenticate; Firestore must remain default-deny and remote writes must remain off.
- A trusted administrator can bypass Firestore Rules with Admin SDK credentials. Keep administrative access least-privileged, private, and out of source control.
- This is a plan, not evidence of current Firebase Console state. No deployed database, rules, auth restrictions, billing plan, or live account state was verified.

## Approval boundary

Planning only. No application code, Firebase config, Firestore rules/indexes, account state, dependencies, billing, database contents, deployment, or commit was changed. Do not enable remote reads/writes until the rules-first gate, emulator tests, and explicit implementation/deployment approval are complete.

## Implementation follow-through note (2026-10-14)

The File-to-15-Day Task Planner (Phase 7) has since been implemented locally in the working tree and is awaiting final verification. A first approval-only rolling carryover proposal has also been added as a partial Phase 12 implementation. It uses prior imported task records and the schema-v5 atomic import receipt; it does not cover goal/deadline analysis, full routine workload constraints, or complete prior-version comparison. No automatic plan activation occurs. Task completion now supports local private evidence attachments as a partial Phase 8 slice, and Android has a Usage Access query/UI as a partial Phase 9 slice. Neither has device-level verification.

The remaining implementation is full Learning sessions/evidence lifecycle (Phase 8), Reports/Export (Phase 11), full adaptive planning (Phase 12), device verification for Android Screen Time (Phase 9), and Secure Cloud Sync (Phase 6). The roadmap's dependency labels remain authoritative: cloud sync requires trusted verified UIDs, reviewed Firestore rules, emulator security tests, and a separately approved rollout before remote writes. No such rules/UID inputs are present, so production sync remains disabled. PDF/JSON reports and full learning sessions are not implemented.
