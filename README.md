# LIFE OS

LIFE OS is an Android-first personal life-management app built with Flutter. It combines local planning and tracking with opt-in prayer reminders. The project is an active prototype; it has not been reviewed or configured for production use.

## What works today

- Local tasks, routines, goals, habits, completion history, and measurements stored in Drift/SQLite.
- Import and review of 15-day task plans from supported files, plus an approval-based rolling carryover proposal. Import and carryover remain local.
- Manual prayer schedules, prayer logs, and optional Android reminders. LIFE OS does not calculate prayer times.
- Local fasting, sleep, and workout records; task-completion evidence files stored on-device.
- A local JSON backup and restore flow for the signed-in account's app records. Evidence file contents are excluded; restore behavior should be reviewed before relying on it as a disaster-recovery system.
- Fifteen-day PDF report preview, save, print, and share.
- Android app-usage summaries after the user grants Android Usage Access.
- Firebase email/password authentication code and protected app routes. There is no public account-creation screen.

## Experimental and unavailable

- Assigned-task sharing has a Firestore adapter and local security rules, but its feature flag is off by default. It is not a supported production synchronization feature.
- General personal-record synchronization is not implemented. Personal records, history, evidence, backups, and reports remain local.
- Android notification delivery and Usage Access need device-level verification. Database encryption, evidence cleanup after task deletion, and complete adaptive planning are not implemented.
- Firebase project setup, account restrictions, deployed rules, and trusted member records are not verified for production.
- The Android release build currently uses the debug signing configuration and the example application ID `com.example.life_os`; it is not a store-ready release package.

## Technology and layout

Flutter/Dart, Riverpod, GoRouter, Drift/SQLite, Firebase Authentication, Cloud Firestore, and Firebase Functions. Feature code lives under `lib/features/`; local data uses the versioned Drift database. Firebase is used for authentication and a separately gated assigned-task projection, not general record sync.

Useful project notes are in [implementation status](docs/IMPLEMENTATION_STATUS.md), [architecture decisions](docs/DECISIONS.md), and the [project specification](docs/PROJECT_SPEC.md). The specification includes planned requirements and should not be read as a list of delivered features.

## Develop locally

Install Flutter/Dart, Android Studio or Android SDK tools, Node.js, npm, and the Firebase CLI. Then run from the repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Cloud Functions unit tests:

```bash
node functions/test/auth_allowlist.test.js
```

Firestore Rules tests require Java 21 or later, the Firestore Emulator, and the test dependencies. Install them once with `npm ci --prefix security-tests`. Tests use the isolated `demo-life-os` project ID; do not replace it with a production project ID:

```bash
firebase emulators:exec --project demo-life-os --only firestore "node security-tests/firestore.rules.test.cjs"
```

## Configure your own Firebase project

Firebase client configuration is project-specific. Create your own Firebase project and Android app, enable Email/Password sign-in if needed, install FlutterFire CLI, then generate local options:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project YOUR_PROJECT_ID --platforms android
```

The generated `lib/firebase_options.dart` and `android/app/google-services.json` are ignored by Git. Never place service-account credentials in the app. Firebase client API keys and app IDs identify a project but are not server credentials; protect data with authentication and server-side Rules.

The Functions in `functions/` use Firebase Authentication blocking events and the `LIFE_OS_ALLOWED_EMAILS` deployment parameter. Configure that parameter privately with the exact invited account addresses; never commit the values. The app has no public sign-up UI, but an allowlist is not enforced until the blocking functions are deployed and active. These functions require Firebase Authentication with Identity Platform, and Cloud Functions deployment requires the Blaze billing plan. Check current pricing and set budget alerts before enabling paid services.

### Assigned-task membership provisioning

The client cannot create or edit `lifeOsMembers` documents. An authorized Firebase administrator must independently verify the intended Auth UIDs, then create one record per paired user at `lifeOsMembers/{uid}` with `active: true` and reciprocal `peerUid` values. Review both identities and the deployed `firestore.rules` before enabling shared tasks. Do not infer membership from an email allowlist, accept a UID from the client, or activate arbitrary users. Deactivate membership to revoke access. This repository does not implement automatic provisioning; production membership and rules are unverified.

To run or deploy Firebase services, explicitly select your own project and review the target first. Deploying Rules or Functions changes a remote project; no deployment is part of the local development commands above.

## Security and data handling

The Firestore Rules default-deny other document paths and forbid client membership writes. The local emulator suite passes against `demo-life-os` using synthetic identities; this does not verify deployed production rules or memberships. The allowlist limits authentication only when its blocking functions are active; it does not provision shared-task membership. Local SQLite and evidence files are not app-level encrypted. Android Auto Backup is not disabled, and the current exclusion rules cover evidence files only; the local database may be included in Android backups depending on device settings. Review that policy before storing real personal records. Backups and PDF reports may contain sensitive data; store and share them accordingly.

## Asset attribution

The bundled Noto Sans Arabic and Bengali fonts include SIL Open Font License 1.1 notices in `assets/fonts/`. The repository has no source or license note for `assets/branding/life_os_icon.png` or the derived Android launcher icons. Confirm that the project owner created or may redistribute that artwork before publishing; add attribution if it came from a third party.

See [SECURITY.md](SECURITY.md) for responsible-disclosure guidance. GitHub private vulnerability reporting has not been verified as enabled for this repository; do not post exploit details in public issues. If no private reporting route is available, request one privately from the repository owner or organization administrator without including vulnerability details.

## License

No license is included. Public visibility does not grant general permission to use, modify, or redistribute this code or its assets. Obtain the owner's license decision before adding a license or granting reuse permission.
