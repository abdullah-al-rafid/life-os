import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../core/database/life_database.dart';
import '../data/firebase_current_user_identity.dart';
import '../data/drift_life_record_store.dart';
import '../domain/life_record_repository.dart';
import '../../planning/domain/planning_repository.dart';
import '../../tracking/data/drift_tracking_entry_store.dart';
import '../../tracking/domain/tracking_entry.dart';
import '../../tracking/domain/tracking_entry_repository.dart';

final lifeDatabaseFactoryProvider = Provider<LifeDatabase Function()>(
  (ref) => LifeDatabase.new,
);

final lifeDatabaseProvider = Provider<LifeDatabase>((ref) {
  final database = ref.watch(lifeDatabaseFactoryProvider)();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final lifeRecordRepositoryProvider = Provider<LifeRecordRepository>((ref) {
  final store = DriftLifeRecordStore(ref.watch(lifeDatabaseProvider));
  final identity = FirebaseCurrentUserIdentity(firebase.FirebaseAuth.instance);
  return OfflineLifeRecordRepository(store, identity);
});

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  final identity = FirebaseCurrentUserIdentity(firebase.FirebaseAuth.instance);
  return PlanningRepository(
    ref.watch(lifeRecordRepositoryProvider),
    DriftPlanningHistoryStore(ref.watch(lifeDatabaseProvider)),
    identity,
  );
});

final planningItemsProvider = StreamProvider.autoDispose
    .family<List<PlanningItem>, PlanningKind?>(
      (ref, kind) =>
          ref.watch(planningRepositoryProvider).watchItems(kind: kind),
    );

final planningHistoryProvider = StreamProvider.autoDispose
    .family<List<PlanningHistoryEntry>, String?>(
      (ref, definitionId) => ref
          .watch(planningRepositoryProvider)
          .watchHistory(definitionId: definitionId),
    );

final trackingEntryRepositoryProvider =
    Provider<OfflineTrackingEntryRepository>((ref) {
      final identity = ref.watch(currentUserIdentityProvider);
      return OfflineTrackingEntryRepository(
        DriftTrackingEntryStore(ref.watch(lifeDatabaseProvider)),
        identity,
        ref.watch(lifeRecordRepositoryProvider),
      );
    });

final currentUserIdentityProvider = Provider<CurrentUserIdentity>(
  (ref) => FirebaseCurrentUserIdentity(firebase.FirebaseAuth.instance),
);

final trackingEntriesProvider = StreamProvider.autoDispose
    .family<List<TrackingEntry>, (TrackingEntryKind?, String?)>(
      (ref, filter) => ref
          .watch(trackingEntryRepositoryProvider)
          .watch(kind: filter.$1, localDate: filter.$2),
    );
