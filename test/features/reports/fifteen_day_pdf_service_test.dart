import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:life_os/features/planning/domain/planning_repository.dart';
import 'package:life_os/features/records/domain/life_record.dart';
import 'package:life_os/features/reports/data/fifteen_day_pdf_service.dart';
import 'package:life_os/features/reports/domain/fifteen_day_report.dart';
import 'package:life_os/features/tracking/domain/tracking_entry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'generates a multipage-capable PDF for all fifteen dates and long notes',
    () async {
      final task = PlanningItem(
        id: 'task-id',
        ownerUid: 'uid-private',
        kind: PlanningKind.task,
        visibility: RecordVisibility.private,
        title: 'বাংলা পড়া - العربية',
        description: '',
        category: '',
        priority: 2,
        scheduledDate: '2026-10-01',
        scheduledMinute: 540,
        durationMinutes: 45,
        recurrence: 'once',
        weekdays: const [],
        targetDate: null,
        startDate: '2026-10-01',
        targetValue: null,
        targetUnit: '',
        archived: false,
        createdAtUtc: DateTime.utc(2026),
        updatedAtUtc: DateTime.utc(2026),
        revision: 1,
      );
      final longNote =
          '${List.filled(400, 'A detailed missed-task reason.').join(' ')} ${List.filled(4000, 'X').join()}';
      final report = const FifteenDayReportBuilder().build(
        period: FifteenDayReportPeriod(DateTime(2026, 10, 1)),
        viewerUid: 'uid-private',
        items: [task],
        history: [
          PlanningHistoryEntry(
            id: 'event',
            ownerUid: 'uid-private',
            definitionId: task.id,
            kind: 'taskCompletion',
            visibility: RecordVisibility.private,
            localDate: '2026-10-01',
            payload: jsonEncode({
              'status': 'notDone',
              'notes': longNote,
              'evidence': [
                {'name': 'proof.txt', 'key': 'secret_storage_key.txt'},
              ],
            }),
            recordedAtUtc: DateTime.utc(2026, 10, 1),
          ),
        ],
        trackingEntries: const <TrackingEntry>[],
      );
      final service = _service(exportTarget: _FakeExportTarget());
      final bytes = await service.generate(report);
      expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
      final structure = latin1.decode(bytes, allowInvalid: true);
      expect(structure, contains('/FontFile2'));
      expect(structure, contains('/ToUnicode'));
      final cmapText = _decompressedPdfStreams(bytes).join('\n');
      expect(cmapText.toUpperCase(), contains('09AC'));
      expect(cmapText.toUpperCase(), matches(RegExp(r'0627|FE8D|FE8E')));
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(structure).length,
        greaterThan(1),
      );
      expect(report.days, hasLength(15));
    },
  );

  test('saves and shares with the export gateway', () async {
    final target = _FakeExportTarget();
    final service = _service(exportTarget: target);
    final report = _emptyReport();
    final path = await service.save(report);
    await service.share(report);
    expect(path, 'local-reports/report.pdf');
    expect(target.saved, isTrue);
    expect(target.shared, isTrue);
    expect(target.bytes!.take(5).toList(), '%PDF-'.codeUnits);
  });

  test('generates a readable PDF for an empty fifteen-day period', () async {
    final bytes = await _service(
      exportTarget: _FakeExportTarget(),
    ).generate(_emptyReport());
    expect(ascii.decode(bytes.take(5).toList()), '%PDF-');
    expect(
      RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
      lessThanOrEqualTo(3),
    );
  });

  test(
    'reports save and share errors to caller without swallowing them',
    () async {
      final saveFailure = _service(
        exportTarget: _FakeExportTarget(failSave: true),
      );
      await expectLater(
        saveFailure.save(_emptyReport()),
        throwsA(isA<StateError>()),
      );

      final shareFailure = _service(
        exportTarget: _FakeExportTarget(failShare: true),
      );
      await expectLater(
        shareFailure.share(_emptyReport()),
        throwsA(isA<StateError>()),
      );
    },
  );
}

List<String> _decompressedPdfStreams(Uint8List bytes) {
  final source = latin1.decode(bytes, allowInvalid: true);
  final output = <String>[];
  for (final match in RegExp(
    r'stream\r?\n([\s\S]*?)\r?\nendstream',
  ).allMatches(source)) {
    final raw = match.group(1);
    if (raw == null) continue;
    try {
      final decompressed = ZLibDecoder().convert(latin1.encode(raw));
      output.add(latin1.decode(decompressed, allowInvalid: true));
    } on FormatException {
      continue;
    }
  }
  return output;
}

FifteenDayPdfService _service({required ReportPdfExportTarget exportTarget}) =>
    FifteenDayPdfService(
      exportTarget: exportTarget,
      assetLoader: (path) async {
        final bytes = await File(path).readAsBytes();
        return ByteData.sublistView(Uint8List.fromList(bytes));
      },
    );

FifteenDayReport _emptyReport() => const FifteenDayReportBuilder().build(
  period: FifteenDayReportPeriod(DateTime(2026, 10, 1)),
  viewerUid: 'uid',
  items: [],
  history: [],
  trackingEntries: [],
);

class _FakeExportTarget implements ReportPdfExportTarget {
  _FakeExportTarget({this.failSave = false, this.failShare = false});
  final bool failSave, failShare;
  bool saved = false;
  bool shared = false;
  Uint8List? bytes;

  @override
  Future<String> save(Uint8List bytes, String filename) async {
    if (failSave) throw StateError('save failed');
    saved = true;
    this.bytes = bytes;
    return 'local-reports/report.pdf';
  }

  @override
  Future<void> share(Uint8List bytes, String filename) async {
    if (failShare) throw StateError('share failed');
    shared = true;
    this.bytes = bytes;
  }
}
