# LIFE OS: Human-Reviewed 15-Day Task Import

**Verified from the repository:** LIFE OS includes a local 15-day task-plan importer for users who want to turn a prepared plan or source material into dated tasks. It provides a preview to edit and approve before saving tasks. Commit [`792c8f5`](../../commit/792c8f58d17fd95a954518710d9cbc5df8c27e6f) introduced the importer, screen, tests, and XLSX template. Later related history includes `dba2725` and `ece57fc`.

## Workflow

The screen presents the flow as “Upload → review → approve.” A user selects one XLSX, CSV, TXT, PDF, or DOCX file, sets the Day 1 date and daily time capacity, then generates a preview covering all 15 dates. The user can edit, remove, reassign, or add tasks before explicitly approving the import. Saved tasks are private by default; existing tasks and completion history are preserved. See the [import screen](../../blob/master/lib/features/planning/presentation/task_plan_import_screen.dart#L59-L162), [preview editing and parsing](../../blob/master/lib/features/planning/presentation/task_plan_import_screen.dart#L171-L305), and [approval flow](../../blob/master/lib/features/planning/presentation/task_plan_import_screen.dart#L307-L400).

The parser accepts structured task rows and source material from which it creates deterministic local suggestions. These suggestions are not AI-generated or AI-verified; the UI says source files are not sent to an AI service. The importer's 10 MiB limit, supported formats, and date normalization are in [`task_plan_import.dart`](../../blob/master/lib/features/planning/domain/task_plan_import.dart#L262-L400).

## Safeguards and limits

The code checks file type, size, empty or malformed input, task fields, date/day consistency, duration and priority ranges, dependencies, duplicate task IDs, and repeated normalized titles on the same day. It warns when imported work plus known existing commitments exceeds the selected daily capacity. Overload and preferred-time conflicts require explicit acknowledgement before approval; warnings do not automatically remove tasks. See [approval validation](../../blob/master/lib/features/planning/domain/task_plan_import.dart#L190-L228), [dependency and duplicate checks](../../blob/master/lib/features/planning/domain/task_plan_import.dart#L1156-L1214), and [capacity warnings](../../blob/master/lib/features/planning/domain/task_plan_import.dart#L1216-L1241).

The local Drift store writes task records and their import receipt within one database transaction. It rejects a repeated import identity defined by source fingerprint, start date, and parser version. This is an idempotency safeguard for that exact identity, not semantic duplicate detection across different files or differently worded tasks. See [`planning_repository.dart`](../../blob/master/lib/features/planning/domain/planning_repository.dart#L471-L599) and [`drift_life_record_store.dart`](../../blob/master/lib/features/records/data/drift_life_record_store.dart#L134-L195).

## Test and verification evidence

Importer tests cover XLSX and CSV parsing, field mapping, dependencies, automatic placement, workload warnings, date boundaries, preview edits, duplicate rejection, and TXT, DOCX, and PDF suggestion paths. The PDF test uses a fake text extractor: it verifies page handling but does not verify native Android PDF extraction. Scanned or image-only PDFs are unsupported because they have no extractable text. See [`task_plan_import_test.dart`](../../blob/master/test/features/planning/task_plan_import_test.dart#L13-L68), [capacity and date tests](../../blob/master/test/features/planning/task_plan_import_test.dart#L70-L299), [validation and duplicate tests](../../blob/master/test/features/planning/task_plan_import_test.dart#L325-L459), and [source-format tests](../../blob/master/test/features/planning/task_plan_import_test.dart#L461-L559).

Repository tests verify that an approved 15-day plan creates dated, private tasks; repeated import identity is rejected; and completion history remains present. They also cover edited previews and a day/date mismatch in [`planning_repository_test.dart`](../../blob/master/test/features/planning/planning_repository_test.dart#L345-L455). Widget tests check local-only messaging and supported file types in [`planning_widget_test.dart`](../../blob/master/test/features/planning/planning_widget_test.dart#L16-L30).

[`IMPLEMENTATION_STATUS.md`](../../blob/master/docs/IMPLEMENTATION_STATUS.md#L73-L75) records that on 2026-10-20, `flutter analyze` completed with no issues and the full `flutter test` suite passed 153 tests. These are recorded project-wide results, not a separately verified importer-only run. No successful hosted CI run is established here. The implementation status also says actual file-picker behavior and native PDF extraction need Android device verification ([lines 103–109](../../blob/master/docs/IMPLEMENTATION_STATUS.md#L103-L109)).

## Codex attribution

Commit `792c8f5` and its author are visible in Git history, but the commit alone does not establish which tools contributed to implementation. For this case study, Codex’s supported role is reviewing the available source, tests, and history and summarizing their evidence; the repository does not independently prove that Codex authored the feature.
