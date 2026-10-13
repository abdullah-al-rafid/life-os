# LIFE OS

Android-first personal life management app for Abdullah Al Rafid and Jannat. The project is currently at the Phase 0 audit baseline; the generated Flutter counter app is not a functional LIFE OS implementation.

## Project documents

- [Complete requirements](docs/PROJECT_SPEC.md)
- [Implementation status](docs/IMPLEMENTATION_STATUS.md)
- [Architecture decisions](docs/DECISIONS.md)

## Requirements

The target implementation uses Flutter/Dart and requires separate authenticated accounts, private personal records, explicitly shared progress, offline-first storage, cross-device synchronization, prayer and routine tracking, learning evidence, Android app-wise screen-time reports, PDF/JSON reports, and approval-based 14-day adaptive planning. See `docs/PROJECT_SPEC.md` for the full requirements.

## Development environment

Audit baseline:

- Flutter 3.41.2 stable
- Dart 3.11.0
- Android SDK 36.1.0 and Android Studio JDK 21 detected
- Gradle wrapper 8.14; Android Gradle Plugin 8.11.1; Kotlin 2.2.20
- Only direct app package is `cupertino_icons`; Firebase, routing, state management, local database, PDF, notification, and usage-statistics packages have not been added.

Install Flutter and Android Studio/SDK, then from the project root run:

```powershell
flutter doctor -v
flutter doctor --android-licenses
flutter pub get
```

Review and accept Android SDK licenses when prompted. Connect an Android device with developer options/USB debugging enabled or start an emulator.

## Firebase setup

Firebase is not configured in this workspace. Before implementing authenticated cloud sync:

1. Create or select a Firebase project you control and register the Android application using the final application ID (currently the starter ID `com.example.life_os`; it should be changed before release).
2. Enable Firebase Authentication sign-in methods selected for the two users and provision separate accounts without sharing passwords.
3. Enable Firestore in an appropriate region and deploy reviewed security rules and indexes.
4. Add the generated Android Firebase configuration using the selected FlutterFire setup. Do not commit private credentials or service-account files. Firebase client configuration is not an admin secret, but must still correspond to the intended project.
5. Configure private evidence storage only after deciding its access policy, retention, and upload limits.

No Firebase configuration or credentials are present now. The project must not claim cloud authentication or synchronization until configuration and rules are in place and verified.

## Permissions and configuration

No runtime permissions are currently declared. Future features will request only what they need: notifications for reminders, Android Usage Access through the system settings flow for app usage statistics, and user-selected media access for evidence. Usage Access is a special user-granted Android setting, not a normal runtime permission. Exact prompts and setup will be documented when those features are implemented. No prayer location/provider, Firebase project, or AI service is currently configured.

## Validation

Current Phase 0 baseline commands:

```powershell
flutter analyze
flutter test
```

Both pass against the generated starter code. These results do not validate LIFE OS requirements. Run Android build/device checks as features are implemented. Android SDK license acceptance is currently outstanding.

## Build

After Android SDK licenses are accepted and an Android device/emulator is available:

```powershell
flutter build apk --debug
```

Release signing, application ID, privacy disclosures, Firebase rules, and permission rationale must be reviewed before any production release. The current Android release configuration uses debug signing and is not release-ready.
