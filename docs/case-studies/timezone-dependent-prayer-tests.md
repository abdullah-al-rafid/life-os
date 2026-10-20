# Fixing Timezone-Dependent Flutter Tests: A LIFE OS Case Study

LIFE OS is an Android-first Flutter prototype with local prayer schedules and optional reminders. Its reminder service takes an injected clock and a timezone, then determines which notifications remain upcoming.

Three prayer reminder tests failed on GitHub Actions even though they passed on the developer’s Bangladesh-time machine. The issue was in the test fixtures’ interpretation of time, not in production scheduling logic.

## What went wrong

The tests used `DateTime(...)` values such as `DateTime(2026, 10, 14, 4)`. In Dart, that constructor creates a date and time in the machine’s local timezone. The service then converts that value to the configured prayer timezone, `Asia/Dhaka`, before scheduling reminders ([`prayer_reminder_service.dart`](../../lib/features/prayer/domain/prayer_reminder_service.dart#L297-L310)).

On a Bangladesh-time machine, `04:00` local is `22:00 UTC` on the previous date, which converts back to `04:00` in Dhaka. **Inference:** Because the workflow uses GitHub’s `ubuntu-latest` runner ([`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml#L13-L16)), the test’s host-local `04:00` would be interpreted as UTC if that runner used its usual UTC timezone; it would then convert to `10:00` in Dhaka. The exact timezone of the failing hosted run has not been verified from its logs.

**Inference:** This six-hour difference explains the reported failures:

- The inexact-scheduling test no longer sees future Fajr notifications because Fajr has already passed in the converted time.
- The past-reminder test sees its expected `05:15` reminder as already past.
- The snooze test calculates a snooze after its `05:40` Jamaat cutoff.

## The fix

Commit [`54559e3`](https://github.com/abdullah-al-rafid/life-os/commit/54559e3) updates the test fixture times to explicit UTC instants representing the intended Dhaka times. For example, `DateTime.utc(2026, 10, 13, 23, 12)` represents `05:12` on October 14 in Dhaka ([`prayer_reminder_service_test.dart`](../../test/features/prayer/prayer_reminder_service_test.dart#L107-L126)).

The fixture’s `todayKey` now converts the injected instant using the fixture’s configured timezone before deriving its date ([`prayer_reminder_service_test.dart`](../../test/features/prayer/prayer_reminder_service_test.dart#L297-L328)). The default clock and snooze case were updated to use explicit UTC instants as well ([test fixture and snooze case](../../test/features/prayer/prayer_reminder_service_test.dart#L233-L275)).

The dismissal test also explicitly checks that the session key was written to the fake preference store ([`prayer_reminder_service_test.dart`](../../test/features/prayer/prayer_reminder_service_test.dart#L233-L256)).

## What the tests verify

- **Inexact scheduling:** Without exact-alarm access, the service reports an inexact-scheduling warning, schedules the expected seven Fajr notifications, and passes `exact: false` to its gateway ([test](../../test/features/prayer/prayer_reminder_service_test.dart#L56-L76)).
- **Past reminders and Jamaat:** At `05:12`, with Jamaat at `05:20`, only the `05:15` reminder remains scheduled. The service skips elapsed reminders and stops before Jamaat ([test](../../test/features/prayer/prayer_reminder_service_test.dart#L107-L126); [scheduling logic](../../lib/features/prayer/domain/prayer_reminder_service.dart#L354-L379)).
- **Dismissal and snooze:** The test checks the dismissed session in the fake preference store and confirms the Fajr requests are canceled. Two sequential snooze actions result in one scheduled snooze ([test](../../test/features/prayer/prayer_reminder_service_test.dart#L233-L275); [service persistence and snooze guard](../../lib/features/prayer/domain/prayer_reminder_service.dart#L495-L533)).

## Verification

**Locally verified:** Available session results show the focused prayer reminder tests passed **11/11**, the full Flutter suite passed **153/153**, and `flutter analyze` reported **no issues**.

**Hosted CI:** Hosted verification remains **unconfirmed**. The repository contains the GitHub Actions workflow, but no exact successful run and commit could be verified, so this article makes no claim that GitHub Actions passed.

## Codex’s role

The available session record shows Codex inspected the reminder service and tests, identified the timezone-sensitive fixtures, updated the tests to use explicit UTC instants and timezone-aware date keys, and ran local checks. This supports describing Codex as part of this debugging task; it does not establish that Codex authored the wider LIFE OS project.

## Limitations

These tests use a fake notification gateway and an in-memory preference store. They do not prove that Android delivers notifications on time or across device states, that preferences survive a real app restart, or that concurrent snooze actions cannot race. Those behaviors need separate device and persistence testing.

## Lessons learned

- Use explicit instants in tests, then convert them to the timezone being tested.
- Derive local dates in the configured timezone, not the host machine’s timezone.
- Treat local test results and hosted CI results as separate evidence.

## Reproducibility

Run these commands from the repository root:

```bash
flutter test test/features/prayer/prayer_reminder_service_test.dart
flutter test
flutter analyze
```
