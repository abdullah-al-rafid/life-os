# LIFE OS — Master Project Requirements & Development Instructions

You are the primary coding agent responsible for implementing my existing Flutter project, LIFE OS, in the current VS Code workspace.

Your goal is to build a complete, maintainable, secure, functional Android-first personal life management application. Do not stop at a UI prototype or create fake functionality.

## 1. Working rules

- Inspect the existing workspace before changing files.
- Preserve useful existing work.
- Work directly in the current project directory.
- Make changes in small, logically grouped, testable phases.
- Keep a `docs/PROJECT_SPEC.md` file containing the complete requirements.
- Keep a `docs/IMPLEMENTATION_STATUS.md` file with completed, in-progress, blocked, and pending features.
- Keep a `docs/DECISIONS.md` file recording important architecture and implementation decisions.
- Maintain a practical README with setup, permissions, configuration, testing, and build instructions.
- After each phase, run applicable formatting, static analysis, and tests; fix errors before proceeding.
- Never claim a feature is complete unless its implementation and tests support that claim.
- Do not silently skip requirements.
- Do not create fake data paths or placeholder buttons presented as working features.
- Ask me only when an essential decision or external credential is genuinely required. Otherwise use sensible, documented defaults.
- Explain necessary manual actions in simple, numbered instructions.
- Never print, commit, or expose passwords, API keys, service account secrets, or other credentials.
- Never weaken security rules to make a feature work.
- Do not overwrite or delete unrelated files.
- Before destructive changes or major architectural changes, explain the reason and obtain approval.
- Maintain backward-compatible data migrations where practical.

## 2. Application identity

App name: LIFE OS

Target: Android-first Flutter application.

Users:
1. Abdullah Al Rafid
2. Jannat

This application is intended for these two users, not as a public multi-tenant SaaS product.

Both users must have separate authenticated accounts and passwords. They should be able to view each other's explicitly shared routines, completion status, progress, learning evidence, and app-wise screen-time reports.

Private authentication data and any explicitly private profile information must remain protected. Each user must only be able to modify their own records, except for clearly defined shared actions that both are authorized to perform.

Use Firebase Authentication and Firestore for secure identity and cross-device synchronization. Use an offline-first local database, preferably Drift/SQLite, with a deliberate synchronization strategy.

Do not assume Firebase is already configured. Inspect the current setup first. If credentials or Firebase project configuration are missing, explain exactly what I must do.

## 3. Design requirements

Create a modern, polished, futuristic productivity interface.

Visual direction:
- Dark navy and near-black surfaces.
- Cyan and purple accent colors.
- Consistent spacing, typography, cards, icons, and responsive layouts.
- Clear visual hierarchy, readable contrast, and accessible touch targets.
- Professional charts, progress indicators, and useful empty states.
- Light animation only where it improves usability.
- Avoid excessive decoration and unnecessary complexity.

Use reusable theme tokens and shared widgets. Do not duplicate entire screens for small visual variations.

Suggested navigation:
- Home
- Plan
- Goals
- Insights
- Profile/Settings

Adapt the navigation if the existing architecture provides a better maintainable option.

## 4. Core daily planning

Implement:
- Daily routines and scheduled tasks.
- Create, edit, view, reschedule, and archive tasks.
- Task completion states: Done, Partial, Not Done.
- Scheduled time, duration, priority, category, notes, and recurrence where appropriate.
- Goals, milestones, and measurable progress.
- Habit tracking and historical completion logs.
- Gym/exercise tracking.
- Sleep schedule and sleep-duration tracking.
- Daily summaries and completion percentages.
- Reminder scheduling and notification preferences.
- Historical records that remain available after a task or plan changes.

Do not overwrite historical completion records when creating a new plan.

## 5. Rolling 14-day adaptive planning

Plan the next 14 days at a time rather than generating an unnecessarily long fixed plan.

At the end of a planning period, the application should support exporting the previous period's data for review and preparing the next plan based on actual performance.

Analyze:
- Completed, partially completed, and missed tasks.
- Schedule adherence.
- Overloaded or unrealistic days.
- Habit consistency.
- Learning progress and evidence.
- Prayer, fasting, exercise, and sleep records.
- Screen-time trends.

The planning engine may propose changes to future schedules, priorities, durations, and task distribution.

CRITICAL: It must never automatically make a significant schedule change without explicit user approval. Show the proposed changes and their reasons. Preserve the previous plan and record approved changes.

Avoid pretending that AI analysis exists if no real model or analysis service has been configured. Start with a transparent rules-based planner if necessary, with a clean interface for adding an AI provider later.

## 6. Prayer and fasting

Implement daily prayer tracking and configurable local prayer times.

Requirements:
- Record prayer completion and optional Jamaat status.
- Allow daily configuration or adjustment of Azan and Jamaat times.
- Support appropriate reminders at configured times.
- Allow repeated reminders between Azan and Jamaat, with configurable frequency and a way to dismiss, snooze, or disable them.
- Prevent duplicate or stale scheduled notifications when times change.
- Handle notification permissions, timezone changes, and device restarts appropriately.
- Provide daily fasting mode that can be enabled or disabled separately for each day.
- Track fasting status and relevant notes without assuming that every day is a fasting day.
- Make reminder behavior configurable and respectful.

Do not hardcode one city's prayer times as universal. If automatic prayer-time calculation or an external provider is needed, make the location, calculation method, and fallback behavior configurable.

## 7. Learning and evidence

Implement learning goals and learning sessions with:
- Topic, task, start/end time, duration, and notes.
- Progress status.
- Screenshot or image evidence attachment.
- Evidence timestamps and association with the correct user and task.
- Secure storage and retrieval.
- Evidence included in relevant reports when selected.
- Upload progress, file validation, and useful error handling.

Use appropriate private storage permissions and access controls. Do not make evidence publicly accessible.

## 8. Android app-wise Screen Time

Implement real Android application usage statistics using the appropriate Android usage-statistics APIs, such as UsageStatsManager, through a maintained Flutter plugin or a small native Kotlin platform-channel implementation if needed.

Requirements:
- Explain and request Android Usage Access through the appropriate system settings flow.
- Check whether access has actually been granted.
- Show a useful explanation and recovery path if permission is missing.
- Report usage duration per installed app and aggregate totals for selected periods.
- Support daily history and date-range summaries where the operating system makes the data available.
- Provide app labels and suitable icons where practical.
- Distinguish unavailable data from genuine zero usage.
- Account for Android version restrictions, permissions, background limitations, and data aggregation boundaries.
- Share app-wise usage reports between the two users only as explicitly authorized by this application's sharing policy.
- Do not claim to track another device remotely or in real time unless an actual, consented data-collection mechanism has been implemented.

Never bypass Android security or accessibility protections. Request only necessary permissions and explain their purpose.

## 9. Shared progress and competition

Implement:
- Separate user dashboards.
- Shared daily and weekly progress summaries.
- Comparable completion percentages.
- Habit consistency and learning-progress comparisons.
- A transparent leaderboard or friendly competition view.
- Shared goals where useful.
- Clear attribution of all records to the correct user.
- Firestore synchronization and conflict handling.

Do not allow one user to modify the other's private records. Define ownership and access rules explicitly.

## 10. Reports & Export

Provide a Reports & Export screen in Settings.

Report period options:
- Single day.
- Full week.
- 14 days.
- Custom date range.

Scope:
- Abdullah.
- Jannat.
- Both users.

Include configurable sections:
- Daily routines and task completion.
- Done/Partial/Not Done statistics.
- Goals and habits.
- Prayer and fasting.
- Learning sessions and evidence.
- Gym/exercise and sleep.
- App-wise Screen Time.
- Comparison and aggregate statistics where both users are selected.

Required capabilities:
- Generate a PDF from actual stored data.
- Preview the PDF inside the app.
- Save/export the PDF to a user-accessible location on the device.
- Share the PDF through Android's native share sheet.
- Export structured JSON for detailed analysis and future planning.
- Validate custom date ranges.
- Handle empty reports, large reports, missing evidence, and export failures gracefully.
- Keep historical data intact.
- Use consistent date, time, and duration formatting.

Use an appropriate Flutter PDF package and native Android save/share integrations. Do not treat generating a PDF in memory as equivalent to saving it to the device.

Example report configuration to support:
period = custom
scope = both
from = 2026-10-01
to = 2026-10-14
include learning/evidence = true
include app-wise screen time = true
include prayer/fasting/habits = true

## 11. Architecture and quality

Inspect the current project before selecting the final architecture.

Preferred direction:
- Flutter and Dart.
- Riverpod for state management.
- go_router for navigation.
- Feature-oriented, maintainable code organization.
- Clear separation of presentation, domain logic, repositories, and data sources.
- Firebase Authentication and Firestore for identity and shared synchronization.
- Drift/SQLite for offline-first local persistence.
- A reliable synchronization and migration strategy.
- Appropriate local notifications.
- Android-specific native integration only where required.

Use current stable, compatible package versions rather than blindly copying outdated tutorials.

Implement:
- Input validation.
- Loading, empty, success, and error states.
- Logging that does not leak sensitive information.
- Database schema migrations.
- Firestore security rules and tests.
- Unit tests for business logic.
- Widget tests for critical screens.
- Integration tests for critical workflows where practical.
- Offline behavior and synchronization tests where practical.
- Permission-denied and missing-configuration handling.

Never embed privileged Firebase Admin credentials or private API secrets in the mobile app.

## 12. Required implementation order

Phase 0: Audit the existing project and environment.

Phase 1: Establish project architecture, design tokens, navigation, and reusable UI foundations.

Phase 2: Configure authentication, user profiles, access control, and the two-user data model.

Phase 3: Implement local database, repositories, synchronization, and migration strategy.

Phase 4: Implement routines, tasks, goals, habits, and historical completion logs.

Phase 5: Implement prayer, fasting, notifications, gym, and sleep tracking.

Phase 6: Implement learning sessions and evidence attachments.

Phase 7: Implement Android Screen Time collection and permission handling.

Phase 8: Implement shared progress, comparison, leaderboard, and analytics.

Phase 9: Implement reports, PDF preview, device save/share, JSON export/import, and report validation.

Phase 10: Implement approval-based adaptive planning and 14-day plan generation.

Phase 11: Complete end-to-end testing, accessibility review, performance checks, security review, and release-build validation.

Reorder dependencies when necessary, but document why. Do not claim that later phases are complete merely because screens exist.

## 13. First action — audit only

For now, inspect the existing workspace, Flutter environment, project configuration, and source files.

Create or update only the project documentation needed to capture the requirements and audit results.

Return:
1. Current project status.
2. Flutter/Dart environment and dependency status.
3. Existing files and useful code.
4. Missing setup and any blockers.
5. A prioritized implementation plan.
6. The exact manual actions, if any, I need to perform.

Do not begin a large implementation in this first response. Wait for my approval before making substantial application-code changes.

The objective is a genuinely functional, secure, maintainable LIFE OS app—not just an attractive demo.