import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/widgets/life_os_components.dart';
import '../../../core/widgets/surface_card.dart';
import '../../records/presentation/record_providers.dart';
import '../data/local_json_backup_service.dart';
import '../domain/local_backup.dart';

final localJsonBackupServiceProvider = Provider<LocalJsonBackupService>((ref) {
  return LocalJsonBackupService(
    database: ref.watch(lifeDatabaseProvider),
    identity: ref.watch(currentUserIdentityProvider),
  );
});

class LocalBackupScreen extends ConsumerStatefulWidget {
  const LocalBackupScreen({super.key});

  @override
  ConsumerState<LocalBackupScreen> createState() => _LocalBackupScreenState();
}

class _LocalBackupScreenState extends ConsumerState<LocalBackupScreen> {
  String? _fileName;
  LocalBackupPreview? _preview;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    title: 'Local backup and restore',
    subtitle: 'Review a backup before adding anything to this device.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PrivacySourceLabel(
          source: PrivacySource.privateLocal,
          details: 'This file stays under your control. No cloud sync.',
        ),
        const SizedBox(height: AppSpacing.md),
        const SurfaceCard(
          child: Text(
            'A backup contains this account’s local records, completion history, tracking entries, and 15-day plan import receipts. Other local accounts and remote assigned tasks are excluded. Evidence file contents and device paths are excluded; attachment names remain as unavailable references.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          key: const Key('export_local_backup'),
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export local backup'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('select_local_backup'),
          onPressed: _busy ? null : _pick,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(_fileName ?? 'Choose a LIFE OS JSON backup'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_message case final message?) ...[
          const SizedBox(height: AppSpacing.md),
          _Notice(message: message, error: _messageIsError),
        ],
        if (_preview case final preview?) ...[
          const SizedBox(height: AppSpacing.md),
          _PreviewCard(preview: preview),
          if (preview.errors.isEmpty && preview.additions.total > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const Key('restore_local_backup'),
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'Add ${preview.additions.total} non-duplicate records',
              ),
            ),
          ],
        ],
      ],
    ),
  );

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
      _preview = null;
    });
    try {
      final bytes = await ref.read(localJsonBackupServiceProvider).exportJson();
      final path = await FilePicker.saveFile(
        dialogTitle: 'Save LIFE OS local backup',
        fileName:
            'life_os_backup_${DateTime.now().toUtc().toIso8601String().substring(0, 10)}.json',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        _message = path == null
            ? 'Backup export was cancelled.'
            : 'Local backup saved.';
        _messageIsError = false;
      });
    } on LocalBackupFailure catch (error) {
      _setError(error.message);
    } on Object {
      _setError(
        'Could not export the local backup. Check available storage and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    setState(() {
      _preview = null;
      _message = null;
      _busy = true;
    });
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.size > localBackupMaxBytes) {
        _setError('Backup files must be 50 MB or smaller.');
        return;
      }
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        _setError('The selected file could not be read on this device.');
        return;
      }
      final preview = await ref
          .read(localJsonBackupServiceProvider)
          .preview(bytes);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _preview = preview;
      });
    } on LocalBackupFailure catch (error) {
      _setError(error.message);
    } on Object {
      _setError(
        'Could not open that file. Choose a local LIFE OS JSON backup.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final preview = _preview;
    if (preview == null || !preview.canRestore) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add backup records?'),
        content: Text(
          '${preview.additions.total} records will be added. Existing records and history will not be changed. ${preview.duplicates.total} exact duplicates will be skipped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add records'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(localJsonBackupServiceProvider)
          .restore(preview);
      if (!mounted) return;
      setState(() {
        _preview = null;
        _message =
            'Added ${result.added.total} records. Skipped ${result.skippedDuplicates.total} duplicates.';
        _messageIsError = false;
      });
    } on LocalBackupFailure catch (error) {
      _setError(error.message);
    } on Object {
      _setError(
        'Restore did not complete. No existing records were overwritten.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = true;
    });
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});
  final LocalBackupPreview preview;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Backup preview', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _CountsTable(title: 'In file', counts: preview.fileCounts),
        const SizedBox(height: AppSpacing.sm),
        _CountsTable(title: 'Will add', counts: preview.additions),
        _CountsTable(title: 'Will skip', counts: preview.duplicates),
        if (preview.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final note in preview.notes) Text('• $note'),
        ],
        if (preview.errors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final error in preview.errors)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: _Notice(message: error, error: true),
            ),
        ],
        if (preview.errors.isEmpty && preview.additions.total == 0)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: Text('There are no new records to add.'),
          ),
      ],
    ),
  );
}

class _CountsTable extends StatelessWidget {
  const _CountsTable({required this.title, required this.counts});
  final String title;
  final LocalBackupCounts counts;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall),
      Text(
        'Records ${counts.records} · History ${counts.history} · Tracking ${counts.tracking} · Plan receipts ${counts.importReceipts}',
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.error});
  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(error ? Icons.error_outline : Icons.info_outline),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
