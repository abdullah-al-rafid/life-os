import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../core/widgets/surface_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600
        ? AppSpacing.md
        : width < 1000
        ? AppSpacing.xl
        : 56.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        AppSpacing.xl,
        horizontal,
        AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                _dateLabel(DateTime.now()),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.cyan,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Make room for\nwhat matters.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'A thoughtful start to your day. Your plans and progress will live here.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PlanBanner(onOpenPlan: () => context.go('/plan')),
              const SizedBox(height: AppSpacing.lg),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 680;
                  final cards = const [
                    _OverviewCard(
                      icon: Icons.check_circle_outline_rounded,
                      accent: AppColors.cyan,
                      title: 'Today’s rhythm',
                      detail:
                          'Your routines and tasks will appear here once planning is available.',
                    ),
                    _OverviewCard(
                      icon: Icons.auto_awesome_rounded,
                      accent: AppColors.purple,
                      title: 'A note to self',
                      detail:
                          'Goals, habits, and reflections will have a home here in a future phase.',
                    ),
                  ];
                  if (!twoColumns) {
                    return Column(
                      children: [
                        cards[0],
                        const SizedBox(height: AppSpacing.md),
                        cards[1],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: cards[0]),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: cards[1]),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const EmptyStateView(
                icon: Icons.spa_outlined,
                title: 'Your dashboard is ready to grow',
                message:
                    'There is no personal data yet. LIFE OS will show your real progress here as features are added and you begin using them.',
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text(
                'Built for steady progress · Your data features are not connected yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const _CompactBrand(),
      const Spacer(),
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceRaised,
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    ],
  );
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.bubble_chart_rounded, color: AppColors.cyan, size: 23),
      const SizedBox(width: AppSpacing.xs),
      Text(
        'LIFE OS',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
      ),
    ],
  );
}

class _PlanBanner extends StatelessWidget {
  const _PlanBanner({required this.onOpenPlan});
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF142B35), Color(0xFF171B30)],
      ),
      border: Border.all(color: const Color(0xFF29404B)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x252AD4E7),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const Text(
                'YOUR SPACE',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your next chapter starts small.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The planning tools are being built. Your routines and goals will appear here when ready.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onOpenPlan,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Explore Plan'),
            ),
          ],
        );
        return compact
            ? content
            : Row(
                children: [
                  Expanded(child: content),
                  const SizedBox(width: AppSpacing.lg),
                  const _OrbitGraphic(),
                ],
              );
      },
    ),
  );
}

class _OrbitGraphic extends StatelessWidget {
  const _OrbitGraphic();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    height: 132,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan.withValues(alpha: .16)),
          ),
        ),
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.purple.withValues(alpha: .28)),
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.cyan, AppColors.purple],
            ),
          ),
          child: const Icon(
            Icons.bubble_chart_rounded,
            color: AppColors.canvas,
          ),
        ),
        const Positioned(
          top: 14,
          right: 18,
          child: _OrbitDot(color: AppColors.cyan),
        ),
        const Positioned(
          bottom: 17,
          left: 15,
          child: _OrbitDot(color: AppColors.purple),
        ),
      ],
    ),
  );
}

class _OrbitDot extends StatelessWidget {
  const _OrbitDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .55), blurRadius: 12),
      ],
    ),
  );
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final Color accent;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          detail,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

String _dateLabel(DateTime date) {
  const months = [
    'JANUARY',
    'FEBRUARY',
    'MARCH',
    'APRIL',
    'MAY',
    'JUNE',
    'JULY',
    'AUGUST',
    'SEPTEMBER',
    'OCTOBER',
    'NOVEMBER',
    'DECEMBER',
  ];
  return '${months[date.month - 1]} ${date.day} · ${date.year}';
}
