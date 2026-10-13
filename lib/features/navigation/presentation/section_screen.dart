import 'package:flutter/material.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import 'app_shell.dart';

class SectionScreen extends StatelessWidget {
  const SectionScreen({required this.section, super.key});
  final AppSection section;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 740),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
      ),
    ),
  );
}
