import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/home_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/navigation/presentation/section_screen.dart';
import '../features/planning/domain/planning_repository.dart';
import '../features/planning/presentation/planning_screens.dart';
import '../features/planning/presentation/task_plan_import_screen.dart';
import '../features/planning/presentation/rolling_plan_screen.dart';
import '../features/planning/presentation/shared_tasks_screen.dart';
import '../features/prayer/presentation/prayer_screen.dart';
import '../features/prayer/presentation/prayer_reminder_lifecycle.dart';
import '../features/prayer/presentation/prayer_settings_screen.dart';
import '../features/fasting/presentation/fasting_screen.dart';
import '../features/wellness/presentation/wellness_screen.dart';
import '../features/screen_time/presentation/screen_time_screen.dart';
import '../features/reports/presentation/fifteen_day_report_screen.dart';
import '../features/backup/presentation/local_backup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;
  ref.listen(authStateProvider, (previous, next) => router.refresh());
  router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final path = state.uri.path;
      final isAuthRoute = path.startsWith('/auth/');
      if (auth.isLoading) {
        return path == '/auth/loading' ? null : '/auth/loading';
      }
      if (auth.hasError) return path == '/auth/setup' ? null : '/auth/setup';

      final user = auth.asData?.value;
      if (user == null) {
        return path == '/auth/sign-in' || path == '/auth/reset-password'
            ? null
            : '/auth/sign-in';
      }
      if (isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/loading',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/auth/setup',
        builder: (context, state) => const FirebaseSetupScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            PrayerReminderLifecycle(child: AppShell(child: child)),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/plan',
            name: 'plan',
            builder: (context, state) => const PlanningScreen(kind: null),
          ),
          GoRoute(
            path: '/plan/import',
            name: 'plan-import',
            builder: (context, state) => const TaskPlanImportScreen(),
          ),
          GoRoute(
            path: '/plan/rolling',
            name: 'plan-rolling',
            builder: (context, state) => const RollingPlanScreen(),
          ),
          GoRoute(
            path: '/plan/assigned',
            name: 'plan-assigned',
            builder: (context, state) => const SharedTasksScreen(),
          ),
          GoRoute(
            path: '/together',
            name: 'together',
            builder: (context, state) =>
                const SharedTasksScreen(togetherView: true),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            builder: (context, state) =>
                const PlanningScreen(kind: PlanningKind.goal),
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            builder: (context, state) => const PlanningInsightsScreen(),
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            builder: (context, state) => const PlanningInsightsScreen(),
          ),
          GoRoute(
            path: '/reports/15-day',
            name: 'report-15-day',
            builder: (context, state) => const FifteenDayReportScreen(),
          ),
          GoRoute(
            path: '/prayer',
            name: 'prayer',
            builder: (context, state) => const PrayerScreen(),
          ),
          GoRoute(
            path: '/prayer/settings',
            name: 'prayer-settings',
            builder: (context, state) => const PrayerSettingsScreen(),
          ),
          GoRoute(
            path: '/fasting',
            name: 'fasting',
            builder: (context, state) => const FastingScreen(),
          ),
          GoRoute(
            path: '/wellness',
            name: 'wellness',
            builder: (context, state) => const WellnessScreen(),
          ),
          GoRoute(
            path: '/screen-time',
            name: 'screen-time',
            builder: (context, state) => const ScreenTimeScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) =>
                const SectionScreen(section: AppSection.settings),
          ),
          GoRoute(
            path: '/settings/backup',
            name: 'local-backup',
            builder: (context, state) => const LocalBackupScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
