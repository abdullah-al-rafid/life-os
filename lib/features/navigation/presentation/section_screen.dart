import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/presentation/auth_providers.dart';
import 'app_shell.dart';

class SectionScreen extends ConsumerWidget {
  const SectionScreen({required this.section, super.key});
  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIFE OS / ${section.label.toUpperCase()}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.cyan,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              section.label,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            EmptyStateView(
              icon: section.icon,
              title: '${section.label} is part of the foundation',
              message:
                  'This destination is ready for its feature phase. It does not yet read or change personal data.',
            ),
            if (section == AppSection.settings) ...[
              const SizedBox(height: AppSpacing.lg),
              _AccountCard(ref: ref),
            ],
          ],
        ),
      ),
    ),
  );
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in as', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              user?.email ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
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
          ],
        ),
      ),
    );
  }
}
