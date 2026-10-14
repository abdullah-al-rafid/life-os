# LIFE OS Prayer Notifications: Android Smoke-Test Guide

Status: manual checklist; no device smoke tests are claimed as completed by this document.

## Test setup

The current debug APK is `build/app/outputs/flutter-apk/app-debug.apk`. The Android application ID is `com.example.life_os`. At guide preparation, ADB listed device serial `127.0.0.1:5555` as connected and reported Android 9 (API 28). Recheck the device and API before testing; do not assume this serial remains available.

Use an emulator or a designated test device and an existing test account. Use test prayer times well ahead of the current time (for example, Azan 10 minutes from now and Jamaat 45 minutes from now) so reminder delivery can be observed. The app does not calculate prayer times. Keep the device awake and the app signed in while setting up a case. These checks exercise local notifications and local records; they are not a production database fixture. Do not clear app storage or uninstall the app to reset test state.

From PowerShell in the project directory:

```powershell
adb devices -l
$serial = '127.0.0.1:5555' # Replace with the serial shown by `adb devices -l`.
$apk = (Resolve-Path '.\build\app\outputs\flutter-apk\app-debug.apk').Path
adb -s $serial install -r $apk
adb -s $serial shell am start -n com.example.life_os/.MainActivity
```

`install -r` updates an installed build while retaining app data when Android accepts the signing key. If Android reports a signature mismatch, stop and use a separate test emulator/device; do not uninstall the existing app because that deletes its local data. If the APK is missing, build it with `flutter build apk --debug`, then repeat the install and launch commands. No device installation or launch has been performed as part of preparing this guide.

Sign in using an existing test account. Open **Prayer**, then **Prayer settings**. Configure all five Azan/Jamaat pairs with valid times, enable reminders, and use the app's permission and exact-alarm controls as each scenario requires. Check the app's status/warning text as well as Android's notification shade and app notification settings.

## Checklist

For each case record device model, Android version/API, app build, account alias (never email/password/UID), local timezone, test date/time, steps, expected result, actual result, and whether the result reproduced.

### 1. Notification permission

- [ ] **Granted:** On Android 13/API 33+, grant LIFE OS notification permission when prompted. Enable reminders and confirm the app reports notifications available and scheduled notifications appear at the chosen times.
- [ ] **Denied:** Deny the runtime prompt, or disable LIFE OS notifications in Android App info. Return to Prayer settings and reconcile/resume the app. It should explain that notifications are unavailable and should not claim they are scheduled or delivered. Re-enable permission, return to the app, and confirm reconciliation schedules eligible future notifications.
- [ ] On Android 12 and earlier there is no Android 13-style `POST_NOTIFICATIONS` runtime prompt. Verify notification enablement through the platform's app/channel settings instead. Do not interpret absence of a prompt as an app failure.

Android's notification runtime permission applies from Android 13/API 33. Exact-alarm permission is independent: granting notification permission does not grant exact-alarm access, and exact-alarm access cannot make notifications visible when notifications are disabled. [Android notification permission](https://developer.android.com/develop/ui/compose/notifications/notification-permission)

### 2. Exact-alarm access and inexact fallback

- [ ] On a supported Android 12+ device, allow exact alarms in **Settings → Apps → Special app access → Alarms & reminders** (wording varies), return to LIFE OS, and confirm the exact-available state. Trigger a future test Azan and compare its delivery with its scheduled time.
- [ ] Disable exact-alarm access while keeping notification permission granted. Resume LIFE OS and confirm its explicit delay warning says reminders are inexact/may arrive late. Confirm future notifications are still scheduled and can arrive, while not requiring exact timing.
- [ ] Re-enable exact access, resume, and confirm status refreshes and future reminders reconcile.
- [ ] If Android's UI or the device API does not expose exact-alarm special access, record that case as unsupported on that device; do not count it as a successful fallback test.

For fresh installs targeting Android 13+ on Android 14+, `SCHEDULE_EXACT_ALARM` may be denied by default. The system behavior depends on OS version, target SDK, install/upgrade history, and exemptions. [Android exact-alarm guidance](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)

### 3. Enablement and scheduled delivery

- [ ] With notification permission granted, set a prayer's Azan at least 10 minutes ahead and Jamaat at least 35 minutes after Azan; enable reminders and save.
- [ ] Confirm the app shows reminders enabled and the correct exact/inexact status. Confirm the Android notification channel **Prayer reminders** is enabled.
- [ ] Observe Azan, then reminders at roughly five-minute intervals. There should be no more than six reminder notifications for that prayer session; all reminder times must be before Jamaat. System scheduling and power management can delay or suppress delivery.
- [ ] Turn reminders off and confirm the app no longer schedules future sessions after reconciliation.

### 4. Stable IDs and duplicate prevention across restart

- [ ] Configure one prayer with future test times and enable reminders. Note the expected Azan/reminder times.
- [ ] Close/relaunch the app normally before the next event. Confirm the same planned event does not produce duplicate notifications after app-start reconciliation.
- [ ] Repeat by backgrounding and resuming the app. Confirm one notification at most for each planned slot and no stale notification from the prior schedule.
- [ ] If available, inspect `adb -s $serial shell dumpsys alarm` as supporting evidence only. Android/OEM output is implementation-specific; do not treat alarm-row formatting or counts alone as pass/fail.

### 5. Prayer completion cancels the session

- [ ] Set Azan in the future and Jamaat far enough away to allow multiple reminder times. Enable reminders.
- [ ] Before the next reminder, mark that prayer complete in the Prayer screen.
- [ ] Confirm remaining notifications for that prayer/date are canceled and are not recreated after resume/restart. Other prayers should remain unaffected.

### 6. Jamaat-time edit reconciles affected notifications

- [ ] Schedule a prayer with Azan in the future and Jamaat sufficiently later; enable reminders.
- [ ] Edit Jamaat to an earlier future time. Save and confirm pending reminder times at or after the new Jamaat time are canceled; eligible earlier reminders remain at most once.
- [ ] Move Jamaat later again and confirm eligible future reminders are scheduled without duplicates.
- [ ] Verify prior dated prayer entries and their saved schedule snapshots remain unchanged.

### 7. Notification actions

- [ ] **Dismiss:** From a delivered prayer notification, choose **Dismiss**. Confirm that session's remaining reminders stop, and reconciliation does not restore them for the same prayer/date.
- [ ] **Snooze once:** Choose **Snooze 5 min**. Confirm one snoozed notification is scheduled, no second snooze is accepted for the same session, and the snooze does not extend beyond Jamaat.
- [ ] **Turn off reminders:** Choose **Turn off reminders**. Confirm subsequent prayer reminders stop and do not return after resume/restart. Re-enable only through Prayer settings.
- [ ] If an action button is absent, record Android version, notification style, and whether the notification was expanded. Some Android/OEM notification layouts hide actions until expanded.

### 8. Reboot and resume recovery

- [ ] Schedule at least one future notification and verify it is pending.
- [ ] Reboot the test device. After startup, unlock it, launch LIFE OS, and verify eligible notifications are restored/reconciled without duplicates.
- [ ] Background LIFE OS, wait across one future event, then resume; confirm reconciliation removes stale events and retains eligible ones.
- [ ] Boot restoration is dependent on Android/plugin receiver behavior, OEM startup controls, and device state. Force-stop is a separate scenario and may prevent background delivery until manually reopened.

### 9. Timezone and date changes

- [ ] Record the current local date, timezone, and a saved prayer entry/schedule snapshot. Set a future test notification.
- [ ] Change the device timezone in Android Settings, return to LIFE OS, and verify it refreshes and reconciles future notifications against the device's new local timezone.
- [ ] Confirm existing historical local dates and schedule snapshots are unchanged. Never change historical records to make this test pass.
- [ ] Change the device date forward/back only on a disposable test emulator/device. Resume LIFE OS and verify future scheduling follows the device-local date. Restore automatic date/time afterward.
- [ ] Record any OS/OEM delay in timezone broadcasts or app-resume behavior; this implementation refreshes on foreground and periodic reconciliation, so changes may not be instantaneous while the app is backgrounded.

### 10. Doze, battery restrictions, and force-stop

- [ ] First confirm a normal-mode notification arrives. Then test battery saver/Doze on a disposable test device and compare timing; an inexact notification may be delayed.
- [ ] On an emulator where ADB device-idle commands are supported, an operator may run `adb -s $serial shell dumpsys deviceidle force-idle`, observe behavior, then immediately restore normal idle with `adb -s $serial shell dumpsys deviceidle unforce`. Do not run these on a device needed for other work; OEM behavior varies.
- [ ] Test the manufacturer's battery optimization/background restriction setting if available. Record exact setting and observed delay; do not treat OEM-specific timing as universal.
- [ ] Force-stop only as a deliberate test on the test installation: `adb -s $serial shell am force-stop com.example.life_os`. Do not expect the app to run/reconcile in the background while force-stopped. Manually launch it afterward and check reconciliation. Restore any battery settings changed for the test.

Doze and app standby defer background CPU/network/alarm work; exact alarms and inexact alarms have different handling, but neither guarantees that a visible notification will be delivered at an exact wall-clock time under all device conditions. Force-stop, OEM battery managers, notification channel settings, reboot state, and user restrictions affect outcomes. LIFE OS must not claim delivery merely because a notification was scheduled.

### 11. Sign-out and account switching

- [ ] Using an existing authorized test account A, schedule a future prayer reminder. Record the prayer/time, but do not capture account credentials or UID.
- [ ] Sign out and confirm account A's pending prayer notifications are canceled.
- [ ] Sign in as existing test account B, resume the app, and configure a different future test time if needed. Confirm only B's currently eligible reminders are scheduled; A's private records and notifications must not appear or be recreated.
- [ ] Sign out B and confirm B's notifications are also canceled. If testing only one account, verify sign-out cancels its pending session before ending the test.
- [ ] Do not create Firebase users, change Firebase configuration/rules, or use personal data for this check.

## Current device coverage and limits

The connected device observed when this guide was prepared is Android 9/API 28. It can exercise notification display, scheduling, app resume, restart, and app-level cancellation, but it cannot validate the Android 13 runtime notification permission flow or Android 12+ exact-alarm special-access UI. Use a separate Android 12+ device for exact-alarm access and Android 13+ for the runtime notification prompt; Android 14+ is useful for fresh-install exact-alarm denial behavior. Menu paths, delivery timing, boot restoration, action-button layout, and battery restrictions vary by OS release and manufacturer.

No manual smoke test is asserted as completed. Automated tests use fake notification/time providers and do not prove delivery on a physical device.

## Capturing and reporting a failure

For each failure include the checklist number, exact reproduction steps, expected versus observed result, local test time/timezone, device model, Android version/API, app build (debug APK), notification permission/channel state, exact-alarm state if available, battery mode, and whether the app was foregrounded/backgrounded/force-stopped. Use account aliases such as “test A”; do not include passwords, email addresses, Firebase UIDs, notification payloads containing personal data, or database files.

Capture Android logs immediately after reproducing:

```powershell
adb -s $serial logcat -d -v threadtime > .\prayer-notification-log.txt
```

Review and redact the log before sharing; it may contain unrelated app/device data. Attach the redacted log and a screenshot of the relevant LIFE OS status or Android notification settings. Never attach the local database. To capture the Android API version:

```powershell
adb -s $serial shell getprop ro.build.version.release
adb -s $serial shell getprop ro.build.version.sdk
```

Report whether the issue reproduces after returning to normal notification permission, exact-alarm state, date/time, timezone, and battery settings. Keep the test app's local data intact unless a separate approved test-reset procedure is provided.
