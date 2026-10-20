import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import 'app_shell.dart';

class SectionScreen extends ConsumerWidget {
  const SectionScreen({required this.section, super.key});
  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (section == AppSection.settings) {
      return AppPageScaffold(
        title: 'Settings',
        subtitle: 'Account, privacy, and on-device feature settings.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PrivacySourceLabel(
              source: PrivacySource.privateLocal,
              details: 'General cloud sync is off',
            ),
            const SizedBox(height: AppSpacing.md),
            _AccountCard(ref: ref),
            const SizedBox(height: AppSpacing.md),
            const _SettingsLinks(),
            const SizedBox(height: AppSpacing.md),
            const SurfaceCard(
              child: Text(
                'Personal plans, tracking, prayer settings, and evidence remain on this device. Assigned-task sharing is separately gated.',
              ),
            ),
          ],
        ),
      );
    }
    return AppPageScaffold(
      title: section.label,
      subtitle: 'This destination is ready for its feature phase.',
      child: EmptyStateView(
        icon: section.icon,
        title: '${section.label} is part of the foundation',
        message: 'This destination does not yet read or change personal data.',
      ),
    );
  }
}

class _SettingsLinks extends StatelessWidget {
  const _SettingsLinks();

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        _SettingsLink(
          icon: Icons.notifications_outlined,
          title: 'Prayer reminders and times',
          onTap: () => context.go('/prayer/settings'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: Icons.nightlight_outlined,
          title: 'Prayer schedule',
          onTap: () => context.go('/prayer'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: Icons.event_available_outlined,
          title: 'Fasting log',
          onTap: () => context.go('/fasting'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: Icons.monitor_heart_outlined,
          title: 'Wellness',
          onTap: () => context.go('/wellness'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: Icons.query_stats_outlined,
          title: 'Screen Time access',
          onTap: () => context.go('/screen-time'),
        ),
        const Divider(height: 1),
        _SettingsLink(
          icon: Icons.backup_outlined,
          title: 'Local backup and restore',
          onTap: () => context.go('/settings/backup'),
        ),
      ],
    ),
  );
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: AppSpacing.sm,
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(user?.email ?? 'Signed-in account'),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(authRepositoryProvider).signOut();
                } on AuthFailure catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}
