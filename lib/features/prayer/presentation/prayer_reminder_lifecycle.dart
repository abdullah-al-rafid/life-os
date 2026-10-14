import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prayer_providers.dart';

class PrayerReminderLifecycle extends ConsumerStatefulWidget {
  const PrayerReminderLifecycle({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<PrayerReminderLifecycle> createState() =>
      _PrayerReminderLifecycleState();
}

class _PrayerReminderLifecycleState
    extends ConsumerState<PrayerReminderLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(prayerReminderServiceProvider).reconcile());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prayerReminderStatusProvider);
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
