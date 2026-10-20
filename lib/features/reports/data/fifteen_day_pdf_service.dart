import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/fifteen_day_report.dart';

abstract interface class ReportPdfExportTarget {
  Future<String> save(Uint8List bytes, String filename);
  Future<void> share(Uint8List bytes, String filename);
}

class LocalReportPdfExportTarget implements ReportPdfExportTarget {
  LocalReportPdfExportTarget({Future<Directory> Function()? directoryProvider})
    : _directoryProvider =
          directoryProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _directoryProvider;

  @override
  Future<String> save(Uint8List bytes, String filename) async {
    final root = await _directoryProvider();
    final reports = Directory(p.join(root.path, 'reports'));
    await reports.create(recursive: true);
    final file = File(p.join(reports.path, _safeFilename(filename)));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> share(Uint8List bytes, String filename) =>
      Printing.sharePdf(bytes: bytes, filename: _safeFilename(filename));
}

class FifteenDayPdfService {
  FifteenDayPdfService({
    ReportPdfExportTarget? exportTarget,
    Future<ByteData> Function(String path)? assetLoader,
  }) : exportTarget = exportTarget ?? LocalReportPdfExportTarget(),
       _assetLoader = assetLoader ?? rootBundle.load;

  final ReportPdfExportTarget exportTarget;
  final Future<ByteData> Function(String path) _assetLoader;
  late final Future<_ReportPdfFonts> _fonts = _loadFonts();

  Future<Uint8List> generate(FifteenDayReport report) async {
    final fonts = await _fonts;
    final document = pw.Document(
      title: 'LIFE OS 15-Day Progress Report',
      subject: '${report.period.startKey} to ${report.period.endKey}',
      theme: pw.ThemeData.withFont(
        base: fonts.arabic,
        bold: fonts.arabicBold,
        fontFallback: [fonts.bengali],
      ),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 1000,
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Text(
            'LIFE OS - local report - ${report.period.startKey} to ${report.period.endKey}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ),
        build: (context) => _buildPages(report),
      ),
    );
    return document.save();
  }

  Future<String> save(FifteenDayReport report) async {
    final bytes = await generate(report);
    return exportTarget.save(bytes, reportFilename(report));
  }

  Future<void> share(FifteenDayReport report) async {
    final bytes = await generate(report);
    await exportTarget.share(bytes, reportFilename(report));
  }

  static String reportFilename(FifteenDayReport report) =>
      'life_os_15_day_report_${report.period.startKey}_${report.period.endKey}_${DateTime.now().millisecondsSinceEpoch}.pdf';

  List<pw.Widget> _buildPages(FifteenDayReport report) {
    final widgets = <pw.Widget>[
      pw.Text(
        'LIFE OS 15-Day Progress Report',
        style: pw.TextStyle(
          fontSize: 21,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'Period: ${report.period.startKey} to ${report.period.endKey} (15 days)',
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        'Personal records are local to this device. Shared goals, when included, are explicitly marked local-only and are not synced.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.Text(
        'Remote assigned tasks are not included because dated remote history for this period is unavailable on this device.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.Text(
        'A missing entry means not recorded; it is not treated as zero, missed, or a negative result. Task times are planned estimates; actual work duration is not recorded.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
      pw.SizedBox(height: 12),
      _sectionTitle('Aggregate summary'),
      pw.Text('Planned items: ${report.plannedTaskCount}'),
      pw.Text('Done: ${report.countStatus(ReportTaskStatus.done)}'),
      pw.Text('Partial: ${report.countStatus(ReportTaskStatus.partial)}'),
      pw.Text('Not Done: ${report.countStatus(ReportTaskStatus.notDone)}'),
      pw.Text(
        'Not recorded: ${report.countStatus(ReportTaskStatus.notRecorded)}',
      ),
      pw.Text('Extra work entries: ${report.extraWorkCount}'),
      pw.Text(
        'Estimated planned time: ${report.estimatedPlannedMinutes} minutes',
      ),
      pw.Text('Actual task duration: unavailable (not tracked by the app)'),
      pw.SizedBox(height: 12),
    ];

    if (report.isEmpty) {
      widgets.add(_sectionTitle('Daily summaries'));
      widgets.add(
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'Planned',
            'Done',
            'Partial',
            'Not Done',
            'Not recorded',
          ],
          data: report.days
              .map(
                (day) => [
                  day.date,
                  '${day.plannedTasks.length}',
                  '${_count(day, ReportTaskStatus.done)}',
                  '${_count(day, ReportTaskStatus.partial)}',
                  '${_count(day, ReportTaskStatus.notDone)}',
                  '${_count(day, ReportTaskStatus.notRecorded)}',
                ],
              )
              .toList(growable: false),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey100,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 4,
          ),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
        ),
      );
    } else {
      for (final day in report.days) {
        widgets.add(_sectionTitle('Daily summary - ${day.date}'));
        widgets.add(
          pw.Text(
            'Planned ${day.plannedTasks.length} - Done ${_count(day, ReportTaskStatus.done)} - Partial ${_count(day, ReportTaskStatus.partial)} - Not Done ${_count(day, ReportTaskStatus.notDone)} - Not recorded ${_count(day, ReportTaskStatus.notRecorded)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        );
        widgets.add(pw.SizedBox(height: 4));
        if (day.plannedTasks.isEmpty) {
          widgets.add(pw.Text('No planned tasks or routines for this date.'));
        } else {
          widgets.add(_taskTable(day.plannedTasks));
          widgets.addAll(_taskNotes(day.plannedTasks));
        }
        if (day.extraWork.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_sectionTitle('Extra work'));
          widgets.add(_taskTable(day.extraWork));
          widgets.addAll(_taskNotes(day.extraWork));
        }
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(_trackingSummary(day));
        if (day.screenTime != null) {
          widgets.add(pw.SizedBox(height: 4));
          widgets.add(pw.Text('On-device Screen Time'));
          if (day.screenTime!.isEmpty) {
            widgets.add(
              pw.Text(
                'Android returned no app rows. This does not confirm zero usage.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            );
          } else {
            for (final app in day.screenTime!) {
              widgets.add(
                _flowingText(
                  '${app.label}: ${app.durationMinutes} min',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              );
            }
          }
        }
        widgets.add(pw.SizedBox(height: 12));
      }
    }

    widgets.add(_sectionTitle('Goal progress and contributions'));
    if (report.goals.isEmpty) {
      widgets.add(pw.Text('No visible goals were available for this report.'));
    } else {
      for (final goal in report.goals) {
        widgets.add(
          _flowingText(
            '${goal.title} - ${goal.source.label}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        );
        if (goal.description.isNotEmpty) {
          widgets.add(_flowingText(goal.description));
        }
        widgets.add(
          _flowingText(
            'Status by period end: ${goal.completedByPeriodEnd ? 'Completed' : 'Active'} - ${goal.target == null ? 'No measurable target; progress ${goal.totalByPeriodEnd} ${goal.unit}' : 'Total ${goal.totalByPeriodEnd} / ${goal.target} ${goal.unit}'} - Started ${goal.startDate}${goal.deadline == null ? '' : ' - Deadline ${goal.deadline}'}',
          ),
        );
        if (goal.contributions.isEmpty) {
          widgets.add(pw.Text('No contributions recorded during this period.'));
        } else {
          for (final contribution in goal.contributions) {
            widgets.add(
              _flowingText(
                '${contribution.date} - ${contribution.authorLabel} - ${contribution.amount} ${goal.unit}${contribution.notes.isEmpty ? '' : ' - ${contribution.notes}'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            );
          }
        }
        widgets.add(pw.SizedBox(height: 8));
      }
    }
    widgets.add(_sectionTitle('Screen Time availability'));
    widgets.add(
      pw.Text(switch (report.screenTimeInclusion) {
        ScreenTimeInclusion.notSelected => 'Not selected for this report.',
        ScreenTimeInclusion.unavailable =>
          'Unavailable: Android Usage Access was not available; no usage values were inferred.',
        ScreenTimeInclusion.included =>
          'Included from on-device Android Usage Access after the user opted in.',
      }),
    );
    if (report.isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(
        pw.Text(
          'No task, contribution, tracking, or Screen Time records were available in this period.',
        ),
      );
    }
    widgets.add(pw.SizedBox(height: 10));
    widgets.add(
      pw.Text(
        'This report is for review before the next planning cycle. Prepare the next routine as a CSV outside LIFE OS and review it through the 15-day import workflow.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
    return widgets;
  }

  pw.Widget _taskTable(List<ReportTaskLine> tasks) {
    final table = pw.TableHelper.fromTextArray(
      headers: const [
        'Task',
        'Kind',
        'Priority',
        'Estimate',
        'Status',
        'Source',
      ],
      data: tasks
          .map(
            (task) => [
              task.title,
              task.kind,
              _priority(task.priority),
              '${task.estimatedMinutes} min',
              task.status.label,
              task.source == ReportDataSource.personalLocal
                  ? 'Personal local'
                  : 'Shared local-only',
            ],
          )
          .toList(growable: false),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.4),
        5: const pw.FlexColumnWidth(2),
      },
    );
    return tasks.any((task) => _containsArabic(task.title))
        ? pw.Directionality(textDirection: pw.TextDirection.rtl, child: table)
        : table;
  }

  List<pw.Widget> _taskNotes(List<ReportTaskLine> tasks) => [
    for (final task in tasks)
      if (task.notes.isNotEmpty || task.evidenceReferences.isNotEmpty)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final line in _taskNoteLines(task))
                _flowingText(line, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
  ];

  List<String> _taskNoteLines(ReportTaskLine task) {
    final blocks = <String>['${task.title}:'];
    if (task.notes.isNotEmpty) blocks.add('Notes: ${task.notes}');
    if (task.evidenceReferences.isNotEmpty) {
      blocks.add(
        'Evidence references only; contents not embedded: ${task.evidenceReferences.join(', ')}',
      );
    }
    final lines = <String>[];
    for (final block in blocks) {
      lines.addAll(_splitText(block));
    }
    return lines;
  }

  List<String> _splitText(String text) {
    final lines = <String>[];
    final words = text.split(RegExp(r'\s+'));
    var line = '';
    for (final word in words) {
      if (word.runes.length > 300) {
        if (line.isNotEmpty) {
          lines.add(line);
          line = '';
        }
        final characters = word.runes.toList(growable: false);
        for (var start = 0; start < characters.length; start += 300) {
          final end = (start + 300).clamp(0, characters.length);
          lines.add(String.fromCharCodes(characters.sublist(start, end)));
        }
        continue;
      }
      if (line.isNotEmpty && line.length + word.length + 1 > 300) {
        lines.add(line);
        line = '';
      }
      line = line.isEmpty ? word : '$line $word';
    }
    if (line.isNotEmpty) lines.add(line);
    return lines;
  }

  pw.Widget _flowingText(String text, {pw.TextStyle? style}) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final line in _splitText(text))
        _containsArabic(line)
            ? pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Text(line, style: style),
              )
            : pw.Text(line, style: style),
    ],
  );

  pw.Widget _trackingSummary(ReportDay day) {
    if (day.trackingEntries.isEmpty) {
      return pw.Text(
        'Prayer, fasting, and wellness: no entries recorded for this date.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Recorded prayer, fasting, and wellness data:'),
        for (final entry in day.trackingEntries)
          _flowingText(
            _trackingLine(entry),
            style: const pw.TextStyle(fontSize: 9),
          ),
      ],
    );
  }

  String _trackingLine(dynamic entry) {
    final payload = entry.payload as Map<String, dynamic>;
    final notes = (payload['notes'] as String?)?.trim() ?? '';
    final base = switch (entry.kind.toString().split('.').last) {
      'prayer' =>
        '${entry.entryKey}: ${_readableStatus(payload['status'])}${payload['jamaatStatus'] == null ? '' : ' - ${payload['jamaatStatus']}'}',
      'fasting' => 'Fasting: ${_readableStatus(payload['status'])}',
      'sleep' => 'Sleep: ${_minutes(payload['durationMinutes'])}',
      'workout' =>
        'Workout: ${payload['activity']} - ${_minutes(payload['durationMinutes'])}',
      _ => 'Tracking entry',
    };
    return notes.isEmpty ? base : '$base - Notes: $notes';
  }

  pw.Widget _sectionTitle(String title) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 7, bottom: 4),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    ),
  );

  int _count(ReportDay day, ReportTaskStatus status) =>
      day.plannedTasks.where((task) => task.status == status).length;

  String _priority(int value) => switch (value) {
    1 => 'High',
    3 => 'Low',
    _ => 'Normal',
  };

  String _readableStatus(Object? value) => switch (value) {
    'prayedOnTime' => 'Prayed on time',
    'prayedLate' => 'Prayed late',
    'missed' => 'Missed',
    'fasted' => 'Fasted',
    'notFasted' => 'Did not fast',
    _ => 'Unknown status',
  };

  String _minutes(Object? value) =>
      value is int ? '$value minutes' : 'duration unavailable';

  Future<_ReportPdfFonts> _loadFonts() async {
    final data = await Future.wait([
      _assetLoader('assets/fonts/NotoSansArabic-Regular.ttf'),
      _assetLoader('assets/fonts/NotoSansArabic-Bold.ttf'),
      _assetLoader('assets/fonts/NotoSansBengali-Regular.ttf'),
    ]);
    return _ReportPdfFonts(
      arabic: pw.Font.ttf(data[0].buffer.asByteData()),
      arabicBold: pw.Font.ttf(data[1].buffer.asByteData()),
      bengali: pw.Font.ttf(data[2].buffer.asByteData()),
    );
  }

  bool _containsArabic(String text) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
}

class _ReportPdfFonts {
  const _ReportPdfFonts({
    required this.arabic,
    required this.arabicBold,
    required this.bengali,
  });
  final pw.Font arabic, arabicBold, bengali;
}

String _safeFilename(String filename) =>
    filename.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
