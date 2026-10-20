import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'surface_card.dart';

/// Consistent scroll-safe page frame for feature screens.
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.maxWidth = 1040,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: padding,
          children: [
            PageHeader(title: title, subtitle: subtitle, actions: actions),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          if (subtitle case final subtitle?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      );
      final actionGroup = actions.isEmpty
          ? null
          : Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: actions,
            );
      if (constraints.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            if (actionGroup != null) ...[
              const SizedBox(height: AppSpacing.sm),
              actionGroup,
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: heading),
          if (actionGroup != null) ...[
            const SizedBox(width: AppSpacing.sm),
            actionGroup,
          ],
        ],
      );
    },
  );
}

enum PrivacySource { privateLocal, localOnly, shared, synced, unavailable }

class PrivacySourceLabel extends StatelessWidget {
  const PrivacySourceLabel({required this.source, this.details, super.key});

  final PrivacySource source;
  final String? details;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (source) {
      PrivacySource.privateLocal => (
        'Private · on this device',
        Icons.lock_outline,
        AppColors.textSecondary,
      ),
      PrivacySource.localOnly => (
        'On this device',
        Icons.phone_android,
        AppColors.textSecondary,
      ),
      PrivacySource.shared => (
        'Shared',
        Icons.group_outlined,
        AppColors.purple,
      ),
      PrivacySource.synced => (
        'Synced',
        Icons.cloud_done_outlined,
        AppColors.cyan,
      ),
      PrivacySource.unavailable => (
        'Unavailable',
        Icons.cloud_off_outlined,
        AppColors.textSecondary,
      ),
    };
    final text = details == null ? label : '$label · $details';
    return Semantics(
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  text,
                  softWrap: true,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum TaskVisualStatus { done, partial, notDone }

class TaskStatusSelector extends StatelessWidget {
  const TaskStatusSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final TaskVisualStatus value;
  final ValueChanged<TaskVisualStatus> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SegmentedButton<TaskVisualStatus>(
    segments: const [
      ButtonSegment(value: TaskVisualStatus.done, label: Text('Done')),
      ButtonSegment(value: TaskVisualStatus.partial, label: Text('Partial')),
      ButtonSegment(value: TaskVisualStatus.notDone, label: Text('Not done')),
    ],
    selected: {value},
    onSelectionChanged: enabled
        ? (selection) => onChanged(selection.first)
        : null,
    showSelectedIcon: false,
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.title,
    this.subtitle,
    this.details,
    this.content,
    this.trailing,
    this.status,
    this.onStatusChanged,
    this.statusEnabled = true,
    this.source,
    this.sourceDetails,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? details;
  final Widget? content;
  final Widget? trailing;
  final TaskVisualStatus? status;
  final ValueChanged<TaskVisualStatus>? onStatusChanged;
  final bool statusEnabled;
  final PrivacySource? source;
  final String? sourceDetails;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  if (details != null && details!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        if (content != null) ...[
          const SizedBox(height: AppSpacing.sm),
          content!,
        ],
        if (source != null || status != null) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (source != null)
                PrivacySourceLabel(source: source!, details: sourceDetails),
              if (status != null)
                TaskStatusSelector(
                  value: status!,
                  onChanged: onStatusChanged ?? (_) {},
                  enabled: statusEnabled && onStatusChanged != null,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class ProgressIndicatorCard extends StatelessWidget {
  const ProgressIndicatorCard({
    required this.label,
    required this.value,
    this.total = 1,
    this.trailing,
    this.isOverCapacity = false,
    super.key,
  });

  final String label;
  final double value;
  final double total;
  final String? trailing;
  final bool isOverCapacity;

  @override
  Widget build(BuildContext context) {
    final safeTotal = total > 0 ? total : 1.0;
    final ratio = value / safeTotal;
    final overCapacity = isOverCapacity || value > safeTotal;
    final color = overCapacity
        ? Theme.of(context).colorScheme.error
        : AppColors.cyan;
    return Semantics(
      label: '$label: ${trailing ?? '${(ratio * 100).round()} percent'}',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              color: color,
              backgroundColor: AppColors.outline,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            if (overCapacity) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Over daily capacity', style: TextStyle(color: color)),
            ],
          ],
        ),
      ),
    );
  }
}
