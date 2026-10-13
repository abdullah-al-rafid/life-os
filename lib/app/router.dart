import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/home_screen.dart';
import '../features/navigation/presentation/app_shell.dart';
import '../features/navigation/presentation/section_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
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
            builder: (context, state) =>
                const SectionScreen(section: AppSection.plan),
          ),
          GoRoute(
            path: '/goals',
            name: 'goals',
            builder: (context, state) =>
                const SectionScreen(section: AppSection.goals),
          ),
          GoRoute(
            path: '/insights',
            name: 'insights',
            builder: (context, state) =>
                const SectionScreen(section: AppSection.insights),
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
