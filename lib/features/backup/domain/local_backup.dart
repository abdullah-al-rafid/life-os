class LocalBackupCounts {
  const LocalBackupCounts({
    required this.records,
    required this.history,
    required this.tracking,
    required this.importReceipts,
  });

  final int records;
  final int history;
  final int tracking;
  final int importReceipts;

  int get total => records + history + tracking + importReceipts;
}

class LocalBackupPreview {
  const LocalBackupPreview({
    required this.sourceVersion,
    required this.fileCounts,
    required this.additions,
    required this.duplicates,
    required this.errors,
    required this.notes,
    required this.accountMatches,
    required this.parsed,
  });

  final int? sourceVersion;
  final LocalBackupCounts fileCounts;
  final LocalBackupCounts additions;
  final LocalBackupCounts duplicates;
  final List<String> errors;
  final List<String> notes;
  final bool accountMatches;
  final Object? parsed;

  bool get canRestore =>
      accountMatches && errors.isEmpty && additions.total > 0;
}

class LocalBackupRestoreResult {
  const LocalBackupRestoreResult({
    required this.added,
    required this.skippedDuplicates,
  });

  final LocalBackupCounts added;
  final LocalBackupCounts skippedDuplicates;
}

class LocalBackupFailure implements Exception {
  const LocalBackupFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
