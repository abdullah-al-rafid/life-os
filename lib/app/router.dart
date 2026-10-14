import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/home_screen.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/auth_screens.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/navigation/presentation/section_screen.dart';
import '../features/planning/domain/planning_repository.dart';
import '../features/planning/presentation/planning_screens.dart';

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
        builder: (context, state, child) => AppShell(child: child),
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
            path: '/settings',
            name: 'settings',
            builder: (context, state) =>
                const SectionScreen(section: AppSection.settings),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
