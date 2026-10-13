# LIFE OS

Android-first personal life management app for Abdullah Al Rafid and Jannat. Phase 1 establishes the responsive UI, navigation, design system, and Riverpod foundations. Product data and service features are not connected yet.

## Project documents

- [Complete requirements](docs/PROJECT_SPEC.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Architecture decisions](docs/DECISIONS.md)

## Project structure

```text
lib/
  app/       app entry, router, and design tokens/theme
  core/      reusable UI primitives and state views
  features/  feature-oriented screens (dashboard, navigation)
test/        critical widget coverage
docs/        requirements, status, and architecture decisions
```

The responsive shell uses bottom navigation on compact widths and a persistent side navigation on wide layouts. Home, Plan, Goals, Insights, and Settings are available. Non-Home sections are explicitly foundation screens with no personal data behavior yet.

## Requirements

The target implementation uses Flutter/Dart and requires separate authenticated accounts, private personal records, explicitly shared progress, offline-first storage, cross-device synchronization, prayer and routine tracking, learning evidence, Android app-wise screen-time reports, PDF/JSON reports, and approval-based 14-day adaptive planning. See `docs/PROJECT_SPEC.md` for the full requirements.

## Development environment

Phase 1 was developed with Flutter 3.41.2 stable and Dart 3.11.0. Android SDK 36.1.0 and Android Studio JDK 21 are detected. Gradle wrapper 8.14, Android Gradle Plugin 8.11.1, and Kotlin 2.2.20 are configured.

Direct app packages include `cupertino_icons`, `go_router`, and `flutter_riverpod`. Firebase, local database, PDF, notification, and usage-statistics packages have not been added.

Install Flutter and Android Studio/SDK, then from the project root run:

```powershell
flutter doctor -v
flutter pub get
```

Android SDK licenses are currently unaccepted. To enable Android builds, run `flutter doctor --android-licenses` in a terminal, review the listed licenses, and accept them interactively. Connect an Android device with developer options/USB debugging enabled or start an emulator.

## Firebase setup

Firebase is not configured in this workspace. Before implementing authenticated cloud sync:

1. Create or select a Firebase project you control and register the Android application using the final application ID (currently `com.example.life_os`; it should be changed before release).
2. Enable Firebase Authentication sign-in methods selected for the two users and provision separate accounts without sharing passwords.
3. Enable Firestore in an appropriate region and deploy reviewed security rules and indexes.
4. Add the generated Android Firebase configuration using the selected FlutterFire setup. Do not commit service-account files or privileged credentials.
5. Configure private evidence storage only after deciding its access policy, retention, and upload limits.

No Firebase configuration is present. The project must not claim cloud authentication or synchronization until configuration and rules are in place and verified.

## Permissions and configuration

No runtime permissions are currently declared. Future features will request only what they need: notifications for reminders, Android Usage Access through the system settings flow for app usage statistics, and user-selected media access for evidence. Usage Access is a special user-granted Android setting, not a normal runtime permission. No prayer location/provider or AI service is configured.

## Validation

```powershell
dart format lib test
flutter analyze
flutter test
```

Phase 1 results are recorded in `docs/IMPLEMENTATION_STATUS.md`. These checks validate the UI foundation only. An Android build requires user-reviewed SDK license acceptance and an available Android device/emulator for device testing.

## Build

After Android SDK licenses are accepted and an Android device/emulator is available:

```powershell
flutter build apk --debug
```

Release signing, application ID, privacy disclosures, Firebase rules, and permission rationale must be reviewed before production release. The current Android release configuration uses debug signing and is not release-ready.
