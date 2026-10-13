import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/tokens.dart';

enum AppSection {
  home('Home', '/', Icons.grid_view_rounded),
  plan('Plan', '/plan', Icons.calendar_month_rounded),
  goals('Goals', '/goals', Icons.flag_rounded),
  insights('Insights', '/insights', Icons.insights_rounded),
  settings('Settings', '/settings', Icons.tune_rounded);

  const AppSection(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selected = AppSection.values.indexWhere(
      (section) => section.path == GoRouterState.of(context).uri.path,
    );
    final index = selected < 0 ? 0 : selected;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (wide) _SideNavigation(selectedIndex: index),
                Expanded(child: child),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      context.go(AppSection.values[value].path),
                  destinations: [
                    for (final section in AppSection.values)
                      NavigationDestination(
                        icon: Icon(section.icon),
                        label: section.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({required this.selectedIndex});
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Container(
    width: 248,
    decoration: const BoxDecoration(
      border: Border(right: BorderSide(color: AppColors.outline)),
    ),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.md,
      AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandMark(),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'WORKSPACE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < AppSection.values.length; i++)
          _NavigationItem(
            section: AppSection.values[i],
            selected: i == selectedIndex,
          ),
        const Spacer(),
        const Text(
          'A calmer way to move forward.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({required this.section, required this.selected});
  final AppSection section;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: ListTile(
      minLeadingWidth: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF182632),
      selectedColor: AppColors.cyan,
      leading: Icon(section.icon, size: 20),
      title: Text(section.label),
      onTap: () => context.go(section.path),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: const LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
          ),
        ),
        child: const Icon(Icons.bubble_chart_rounded, color: AppColors.canvas),
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        'LIFE OS',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
