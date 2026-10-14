# LIFE OS

Android-first personal life management app for Abdullah Al Rafid and Jannat. Phases 1–4 establish responsive UI, Firebase email/password authentication, offline-first Drift/SQLite storage, and local task, routine, goal, and habit workflows. Remote synchronization is not implemented.

## Project documents

- [Complete requirements](docs/PROJECT_SPEC.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Architecture decisions](docs/DECISIONS.md)

## Project structure

```text
lib/
  app/       app entry, router, and design tokens/theme
  core/      reusable UI primitives, state views, and database
  features/  feature-oriented screens and repositories (auth, dashboard, navigation, planning, records)
functions/   server-side Identity Platform account allowlist
test/        critical widget coverage
docs/        requirements, status, and architecture decisions
```

The responsive shell uses bottom navigation on compact widths and a persistent side navigation on wide layouts. Home, Plan, Goals, Insights, and Settings are available. Plan supports local task, routine, and habit definitions, completion results, archive, and safe tombstone deletion. Goals keep append-only measurements and show progress. Insights summarizes recent activity and habit history. Authentication includes sign-in, sign-out, password reset, persisted Firebase auth state, and protected app routes. There is no in-app account creation.

## Requirements

The target implementation uses Flutter/Dart and requires separate authenticated accounts, private personal records, explicitly shared progress, offline-first storage, cross-device synchronization, prayer and routine tracking, learning evidence, Android app-wise screen-time reports, PDF/JSON reports, and approval-based 14-day adaptive planning. See `docs/PROJECT_SPEC.md` for the full requirements.

## Development environment

Phase 1 was developed with Flutter 3.41.2 stable and Dart 3.11.0. Android SDK 36.1.0 and Android Studio JDK 21 are detected. Gradle wrapper 8.14, Android Gradle Plugin 8.11.1, and Kotlin 2.2.20 are configured.

Direct app packages include `cupertino_icons`, `go_router`, `flutter_riverpod`, `firebase_core`, `firebase_auth`, `drift`, `path`, and `path_provider`. `drift_dev` and `build_runner` generate the Drift database code. PDF, notification, and usage-statistics packages have not been added. The server-side account gate uses Firebase Functions v2 and Node.js 20.

Install Flutter and Android Studio/SDK, then from the project root run:

```powershell
flutter doctor -v
flutter pub get
```

Android SDK licenses were reported as accepted by `flutter doctor -v` during Firebase configuration verification. Connect an Android device with developer options/USB debugging enabled or start an emulator.

## Firebase authentication setup

Firebase is configured locally for project `life-os-abdullah-jannat`. The generated `lib/firebase_options.dart` contains Android options, and `android/app/google-services.json` is wired through the Google Services Gradle plugin. `main.dart` initializes Firebase with `DefaultFirebaseOptions.currentPlatform` before `runApp`. The generated files are ignored by Git and must be created locally with FlutterFire on each development machine.

To configure a new checkout or regenerate options:

1. Install FlutterFire CLI if needed: `dart pub global activate flutterfire_cli`.
2. Run `flutterfire configure --project <PROJECT_ID> --platforms android` from the project root. Ensure the Firebase Android app uses the current application ID `com.example.life_os`.
3. Run `flutter pub get`. Launch normally; no `firebase.local.json` or `--dart-define` values are required.

To use sign-in, confirm Email/Password is enabled in Firebase Console and use an already provisioned account. The app has no public sign-up screen. Until the Identity Platform allowlist functions are deployed, Firebase may allow any existing email/password account in this project to sign in; the two-user restriction is not active. Deploying those functions requires Identity Platform and Cloud Functions billing and is outside the current phase. Never put account passwords or service-account credentials in the mobile app. See Firebase's [Flutter password auth guide](https://firebase.google.com/docs/auth/flutter/password-auth).

## Offline data foundation

Drift opens `life_os.sqlite` in the app support directory. Schema version 3 contains `profiles` keyed by the supplied Firebase Auth UID, `stored_records`, and an append-only `activity_history` table. Definitions use a common record envelope with typed ownership, visibility, UTC timestamp, revision, sync-status, conflict, and deletion columns; feature data lives in validated JSON payloads. History stores task/routine/habit completion snapshots and goal measurements. Its composite unique key prevents duplicate check-ins per user, definition, and occurrence. Version 3 is additive: it creates the history table without deleting or rewriting existing profiles or records.

Database migrations use Drift's versioned `MigrationStrategy`. Version 2 added a nullable deletion timestamp to the version 1 record table; version 3 adds history. Local timestamps use UTC epoch milliseconds. Scheduled date and time are represented using the device's local calendar date and wall-clock minute; behavior when travelling or changing time zones still needs a product decision. Local deletes create tombstones, and changed records increment a revision.

The repository and remote-store interfaces separate local persistence from future Firestore access. Today all saves stay local with `localOnly` status; `synchronize()` explicitly fails closed. A future conflict with different content is retained for resolution instead of automatically overwriting local data. No Firestore adapter, network read/write, queue, or security rules are implemented.

Repository calls use the current Firebase Auth UID rather than a caller-supplied UID. The record watch switches with auth-state changes and cancels the previous UID's watch on sign-out/account switch. Owner checks and shared/private visibility filters are local app safeguards, not a security boundary. Shared histories are visible to another account only while the current definition remains shared, active, and not tombstoned. All Phase 4 writes remain local; the UI displays that cloud sync is off. Do not enable remote writes until Firestore rules are implemented and tested. The two-account Identity Platform allowlist functions are still undeployed, so Firebase may allow any existing email/password account in the project to sign in.

The database resides in app-specific internal storage. Android's sandbox restricts access by other ordinary apps, while storage encryption depends on Android version/device configuration ([Android storage guidance](https://developer.android.com/training/data-storage/app-specific)). LIFE OS does not add database-level encryption or an app lock. The Android manifest does not declare `allowBackup` or backup rules; Android Auto Backup defaults to enabled and includes most app-internal files, so this SQLite file may be included in cloud or device-transfer backups ([Android Auto Backup](https://developer.android.com/identity/data/autobackup)). Choose and test a backup/restore policy before collecting real records. Because prayer, learning, and screen-time records are personal, evaluate app-level encryption with Android Keystore key management if unlocked-device, backup, rooted-device, or storage-extraction risks are in scope. Keystore key material is designed to be harder to extract than a key stored in app files ([Android Keystore](https://developer.android.com/privacy-and-security/keystore)); encryption would not replace account authorization or server rules.

## Permissions and configuration

No runtime permissions are currently declared. Authentication uses Firebase SDK-managed session persistence; the app does not store passwords. Future features will request only what they need: notifications for reminders, Android Usage Access through the system settings flow for app usage statistics, and user-selected media access for evidence. Usage Access is a special user-granted Android setting, not a normal runtime permission. No prayer location/provider or AI service is configured.

## Validation

```powershell
dart format lib test
flutter analyze
flutter test
```

Phase 2–4 results are recorded in `docs/IMPLEMENTATION_STATUS.md`. Auth widget tests use a fake auth repository and do not validate live sign-in. Data and planning repository tests use in-memory SQLite. Firebase options are loaded locally through the generated FlutterFire file.

## Build

After an Android device/emulator is available:

```powershell
flutter build apk --debug
```

Release signing, application ID, privacy disclosures, Firebase rules, and permission rationale must be reviewed before production release. The current Android release configuration uses debug signing and is not release-ready.
