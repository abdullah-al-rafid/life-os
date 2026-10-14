import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:xml/xml.dart';

import '../../records/domain/life_record.dart';

const int taskPlanMaxFileBytes = 10 * 1024 * 1024;
const String taskPlanParserVersion = '1';

class TaskPlanDraft {
  const TaskPlanDraft({
    required this.id,
    required this.dayOffset,
    required this.date,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.durationMinutes,
    required this.completionCriteria,
    required this.dependencies,
    required this.sourceReference,
    required this.suggested,
    required this.visibility,
    this.scheduledMinute = 540,
  });

  final String id;
  final int dayOffset;
  final String date;
  final String title;
  final String description;
  final String category;
  final int priority;
  final int durationMinutes;
  final String completionCriteria;
  final List<String> dependencies;
  final String sourceReference;
  final bool suggested;
  final RecordVisibility visibility;
  final int scheduledMinute;

  TaskPlanDraft copyWith({
    int? dayOffset,
    String? date,
    String? title,
    String? description,
    String? category,
    int? priority,
    int? durationMinutes,
    String? completionCriteria,
    List<String>? dependencies,
    String? sourceReference,
    bool? suggested,
    RecordVisibility? visibility,
    int? scheduledMinute,
  }) => TaskPlanDraft(
    id: id,
    dayOffset: dayOffset ?? this.dayOffset,
    date: date ?? this.date,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    completionCriteria: completionCriteria ?? this.completionCriteria,
    dependencies: dependencies ?? this.dependencies,
    sourceReference: sourceReference ?? this.sourceReference,
    suggested: suggested ?? this.suggested,
    visibility: visibility ?? this.visibility,
    scheduledMinute: scheduledMinute ?? this.scheduledMinute,
  );
}

class TaskPlanProposal {
  const TaskPlanProposal({
    required this.fileName,
    required this.fingerprint,
    required this.startDate,
    required this.dailyCapacityMinutes,
    required this.tasks,
    required this.warnings,
    required this.format,
  });

  final String fileName;
  final String fingerprint;
  final DateTime startDate;
  final int dailyCapacityMinutes;
  final List<TaskPlanDraft> tasks;
  final List<String> warnings;
  final String format;

  List<String> get dates =>
      List.generate(15, (i) => _dateKey(startDate.add(Duration(days: i))));
}

class TaskPlanCommitment {
  const TaskPlanCommitment({
    required this.recurrence,
    required this.durationMinutes,
    this.scheduledDate,
    this.weekdays = const [],
  });
  final String recurrence;
  final int durationMinutes;
  final String? scheduledDate;
  final List<int> weekdays;

  bool occursOn(DateTime date) => switch (recurrence) {
    'daily' => true,
    'weekdays' =>
      date.weekday >= DateTime.monday && date.weekday <= DateTime.friday,
    'weekly' =>
      weekdays.isEmpty
          ? date.weekday == DateTime.monday
          : weekdays.contains(date.weekday),
    _ => scheduledDate == _dateKey(date),
  };
}

class TaskPlanImportFailure implements Exception {
  const TaskPlanImportFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class TaskPlanImporter {
  TaskPlanImporter({PdfTextExtractor? pdfTextExtractor})
    : _pdfTextExtractor = pdfTextExtractor ?? const LocalPdfTextExtractor();

  final PdfTextExtractor _pdfTextExtractor;

  Future<TaskPlanProposal> parse({
    required String fileName,
    required Uint8List bytes,
    DateTime? startDate,
    int? dailyCapacityMinutes,
    Map<String, int> occupiedMinutesByDate = const {},
    List<TaskPlanCommitment> existingCommitments = const [],
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    if (!{'xlsx', 'csv', 'txt', 'pdf', 'docx'}.contains(ext)) {
      throw const TaskPlanImportFailure(
        'Choose an XLSX, CSV, TXT, PDF, or DOCX file.',
      );
    }
    if (bytes.isEmpty) {
      throw const TaskPlanImportFailure('The selected file is empty.');
    }
    if (bytes.length > taskPlanMaxFileBytes) {
      throw const TaskPlanImportFailure('Files must be 10 MB or smaller.');
    }
    final fingerprint = sha256.convert(bytes).toString();
    final warnings = <String>[];
    late DateTime planStart;
    late int capacity;
    late List<TaskPlanDraft> tasks;
    switch (ext) {
      case 'xlsx':
        final brief = _parseXlsx(bytes, warnings);
        planStart = startDate ?? brief.startDate ?? _today();
        capacity = dailyCapacityMinutes ?? brief.capacity ?? 120;
        tasks = brief.tasks;
        if (tasks.isEmpty) {
          tasks = _suggestFromBrief(
            brief,
            planStart,
            capacity,
            _occupancy(planStart, occupiedMinutesByDate, existingCommitments),
            warnings,
          );
        }
      case 'csv':
        planStart = startDate ?? _today();
        capacity = dailyCapacityMinutes ?? 120;
        tasks = _parseCsv(_decodeText(bytes), planStart, warnings);
      case 'txt':
        planStart = startDate ?? _today();
        capacity = dailyCapacityMinutes ?? 120;
        tasks = _suggestFromLines(
          _decodeText(bytes),
          planStart,
          capacity,
          'Text line',
          _occupancy(planStart, occupiedMinutesByDate, existingCommitments),
          warnings,
        );
      case 'pdf':
        planStart = startDate ?? _today();
        capacity = dailyCapacityMinutes ?? 120;
        final pages = await _pdfTextExtractor.extractPages(bytes);
        tasks = _suggestFromPages(
          pages,
          planStart,
          capacity,
          _occupancy(planStart, occupiedMinutesByDate, existingCommitments),
          warnings,
        );
      case 'docx':
        planStart = startDate ?? _today();
        capacity = dailyCapacityMinutes ?? 120;
        tasks = _suggestFromLines(
          _extractDocxParagraphs(bytes).join('\n'),
          planStart,
          capacity,
          'Paragraph',
          _occupancy(planStart, occupiedMinutesByDate, existingCommitments),
          warnings,
        );
    }
    if (capacity < 1 || capacity > 1440) {
      throw const TaskPlanImportFailure(
        'Daily available time must be between 1 and 1440 minutes.',
      );
    }
    if (tasks.isEmpty) {
      throw const TaskPlanImportFailure(
        'No usable tasks or source topics were found. Add task titles or a goal and topics, then try again.',
      );
    }
    tasks = tasks
        .map(
          (task) => task.copyWith(
            date: _dateKey(planStart.add(Duration(days: task.dayOffset - 1))),
          ),
        )
        .toList(growable: false);
    _validateDependencies(tasks);
    _validateDuplicates(tasks);
    _checkCapacity(
      tasks,
      capacity,
      warnings,
      _occupancy(planStart, occupiedMinutesByDate, existingCommitments),
      planStart,
    );
    if (tasks.map((t) => t.dayOffset).toSet().length < 15) {
      warnings.add(
        'Some days have no source task. Review all 15 days and add or reassign tasks if every day needs work.',
      );
    }
    return TaskPlanProposal(
      fileName: fileName,
      fingerprint: fingerprint,
      startDate: DateTime(planStart.year, planStart.month, planStart.day),
      dailyCapacityMinutes: capacity,
      tasks: tasks,
      warnings: List.unmodifiable(warnings.toSet()),
      format: ext.toUpperCase(),
    );
  }

  _WorkbookBrief _parseXlsx(Uint8List bytes, List<String> warnings) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final entries = {for (final entry in archive) entry.name: entry};
      XmlDocument xml(String path) {
        final entry = entries[path];
        if (entry == null || !entry.isFile) {
          throw const TaskPlanImportFailure(
            'The workbook is missing required sheets.',
          );
        }
        return XmlDocument.parse(utf8.decode(entry.readBytes()!));
      }

      final strings = <String>[];
      final shared = entries['xl/sharedStrings.xml'];
      if (shared != null) {
        final doc = XmlDocument.parse(utf8.decode(shared.readBytes()!));
        for (final si in doc.findAllElements('si')) {
          strings.add(si.findAllElements('t').map((n) => n.innerText).join());
        }
      }
      final workbook = xml('xl/workbook.xml');
      final relationships = xml('xl/_rels/workbook.xml.rels');
      final relationTargets = <String, String>{
        for (final rel in relationships.findAllElements('Relationship'))
          rel.getAttribute('Id')!: rel.getAttribute('Target')!,
      };
      final sheetPaths = <String, String>{};
      for (final sheet in workbook.findAllElements('sheet')) {
        final name = sheet.getAttribute('name');
        final relation = sheet.getAttribute(
          'id',
          namespace:
              'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
        );
        if (name == null ||
            relation == null ||
            !relationTargets.containsKey(relation)) {
          continue;
        }
        var path = relationTargets[relation]!;
        if (path.startsWith('/')) path = path.substring(1);
        if (!path.startsWith('xl/')) path = 'xl/$path';
        sheetPaths[name] = path;
      }
      if (!sheetPaths.containsKey('Tasks') ||
          !sheetPaths.containsKey('Source Brief')) {
        throw const TaskPlanImportFailure(
          'This XLSX does not match the LIFE OS template: Tasks and Source Brief sheets are required.',
        );
      }
      Map<int, Map<int, String>> readSheet(String path) {
        final doc = xml(path);
        final rows = <int, Map<int, String>>{};
        for (final row in doc.findAllElements('row')) {
          final rowNumber = int.tryParse(row.getAttribute('r') ?? '');
          if (rowNumber == null) continue;
          final cells = <int, String>{};
          for (final cell in row.findAllElements('c')) {
            final ref = cell.getAttribute('r') ?? '';
            final col = _columnIndex(ref);
            final type = cell.getAttribute('t');
            var value = cell.findElements('v').firstOrNull?.innerText ?? '';
            if (type == 's' && value.isNotEmpty) {
              final index = int.tryParse(value);
              value = index != null && index >= 0 && index < strings.length
                  ? strings[index]
                  : '';
            } else if (type == 'inlineStr') {
              value = cell.findAllElements('t').map((n) => n.innerText).join();
            }
            cells[col] = value.trim();
          }
          rows[rowNumber] = cells;
        }
        return rows;
      }

      final taskSheet = readSheet(sheetPaths['Tasks']!);
      final headerRow = taskSheet[4];
      if (headerRow == null) {
        throw const TaskPlanImportFailure('The Tasks sheet has no header row.');
      }
      final headers = {
        for (final entry in headerRow.entries) _header(entry.value): entry.key,
      };
      int? column(String name) => headers[_header(name)];
      final titleCol = column('Task Title *') ?? column('Task Title');
      final dayCol = column('Day Offset (1-15)');
      if (titleCol == null || dayCol == null) {
        throw const TaskPlanImportFailure(
          'The Tasks sheet needs Day Offset and Task Title columns.',
        );
      }
      final briefRows = readSheet(sheetPaths['Source Brief']!);
      final brief = <String, String>{};
      for (final entry in briefRows.entries.where((e) => e.key >= 4)) {
        final key = entry.value[0]?.trim() ?? '';
        final value = entry.value[1]?.trim() ?? '';
        if (key.isNotEmpty && value.isNotEmpty) brief[key] = value;
      }
      final start = _parseDate(brief['Preferred start date (optional)']);
      final capacity = int.tryParse(
        brief['Available time per day (minutes)'] ?? '',
      );
      final tasks = <TaskPlanDraft>[];
      final rowRefs = <String, TaskPlanDraft>{};
      final rawDependencies = <String, String>{};
      final rows = taskSheet.entries.where((e) => e.key > 4).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in rows) {
        final row = entry.value;
        if (row.values.every((value) => value.isEmpty)) continue;
        final title = row[titleCol]?.trim() ?? '';
        if (title.isEmpty) {
          throw TaskPlanImportFailure('Task row ${entry.key} has no title.');
        }
        final day = int.tryParse(row[dayCol] ?? '');
        if (day == null || day < 1 || day > 15) {
          throw TaskPlanImportFailure(
            'Task row ${entry.key} must use a Day Offset from 1 to 15.',
          );
        }
        final duration = _optionalInt(row[column('Estimated Minutes')]) ?? 30;
        if ((row[column('Estimated Minutes')] ?? '').isEmpty) {
          warnings.add(
            'One or more task rows omit an estimate; a 30-minute default was used. Review workload before importing.',
          );
        }
        if ((row[column('Category')] ?? '').isEmpty) {
          warnings.add(
            'One or more task rows omit a category and default to Other. Review categories before importing.',
          );
        }
        if ((row[column('Description / Outcome')] ?? '').isEmpty) {
          warnings.add(
            'One or more tasks have no description or measurable outcome. Add completion criteria where useful.',
          );
        }
        if (duration < 1 || duration > 1440) {
          throw TaskPlanImportFailure(
            'Task row ${entry.key} has an invalid time estimate.',
          );
        }
        final sourceId = 'row:${entry.key}';
        final draft = TaskPlanDraft(
          id: sourceId,
          dayOffset: day,
          date: '',
          title: title,
          description: row[column('Description / Outcome')] ?? '',
          category: _nonEmpty(row[column('Category')], 'Other'),
          priority: _priority(row[column('Priority')]),
          durationMinutes: duration,
          completionCriteria: row[column('Description / Outcome')] ?? '',
          dependencies: const [],
          sourceReference: _nonEmpty(
            row[column('Source Reference')],
            'Tasks!${entry.key}',
          ),
          suggested: false,
          visibility: _visibility(row[column('Visibility')]),
          scheduledMinute: _parsePreferredTime(row[column('Preferred Time')]),
        );
        tasks.add(draft);
        rowRefs[sourceId] = draft;
        rowRefs[_header(title)] = draft;
        final dependency = row[column('Depends on Task ID')];
        if (dependency != null && dependency.trim().isNotEmpty) {
          rawDependencies[sourceId] = dependency.trim();
        }
      }
      final resolved = tasks
          .map((task) {
            final dependency = rawDependencies[task.id];
            if (dependency == null) return task;
            final parent = rowRefs[dependency] ?? rowRefs[_header(dependency)];
            if (parent == null) {
              warnings.add(
                'Dependency "$dependency" for ${task.title} was not matched to a task title or row reference.',
              );
              return task.copyWith(dependencies: [dependency]);
            }
            return task.copyWith(dependencies: [parent.id]);
          })
          .toList(growable: false);
      return _WorkbookBrief(
        goal: brief['Main goal / desired outcome'] ?? '',
        topics: brief['Source material / topics to cover'] ?? '',
        deadline: brief['Deadline or fixed dates (optional)'] ?? '',
        unavailableDays: brief['Days unavailable / fixed commitments'] ?? '',
        constraints: brief['Must-do items or constraints'] ?? '',
        startDate: start,
        capacity: capacity,
        tasks: resolved,
      );
    } on TaskPlanImportFailure {
      rethrow;
    } on Object {
      throw const TaskPlanImportFailure(
        'Could not read this XLSX. Confirm it is a valid, unencrypted workbook and try again.',
      );
    }
  }

  List<TaskPlanDraft> _parseCsv(
    String text,
    DateTime start,
    List<String> warnings,
  ) {
    final rows = csv.decode(text);
    if (rows.isEmpty) {
      throw const TaskPlanImportFailure('The CSV contains no rows.');
    }
    final headers = {
      for (var i = 0; i < rows.first.length; i++)
        _header('${rows.first[i]}'): i,
    };
    int? col(List<String> names) {
      for (final name in names) {
        final value = headers[_header(name)];
        if (value != null) return value;
      }
      return null;
    }

    final titleCol = col(['Task Title', 'Title', 'Task']);
    if (titleCol == null) {
      throw const TaskPlanImportFailure(
        'CSV must include a Task Title, Title, or Task column.',
      );
    }
    if (col(['Day Offset', 'Day', 'Day Number']) == null) {
      warnings.add(
        'CSV has no day column; source tasks are assigned in order across the 15-day window.',
      );
    }
    if (col(['Estimated Minutes', 'Duration', 'Duration Minutes']) == null) {
      warnings.add(
        'CSV has no duration column; missing task estimates default to 30 minutes for review.',
      );
    }
    if (col(['Category']) == null) {
      warnings.add(
        'CSV has no category column; tasks default to Other. Review categories before import.',
      );
    }
    final tasks = <TaskPlanDraft>[];
    final dependenciesById = <String, String>{};
    final aliases = <String, String>{};
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((v) => '$v'.trim().isEmpty)) continue;
      String read(List<String> names, [String fallback = '']) {
        final idx = col(names);
        return idx == null || idx >= row.length
            ? fallback
            : '${row[idx]}'.trim();
      }

      final title = titleCol >= row.length ? '' : '${row[titleCol]}'.trim();
      if (title.isEmpty) {
        throw TaskPlanImportFailure('CSV row ${i + 1} has no task title.');
      }
      final offset =
          int.tryParse(read(['Day Offset', 'Day', 'Day Number'])) ??
          tasks.length % 15 + 1;
      if (offset < 1 || offset > 15) {
        throw TaskPlanImportFailure(
          'CSV row ${i + 1} has a Day Offset outside 1–15.',
        );
      }
      final duration =
          int.tryParse(
            read(['Estimated Minutes', 'Duration', 'Duration Minutes']),
          ) ??
          30;
      if (duration < 1 || duration > 1440) {
        throw TaskPlanImportFailure(
          'CSV row ${i + 1} has an invalid duration.',
        );
      }
      final description = read([
        'Description',
        'Description / Outcome',
        'Notes',
      ]);
      final taskId = 'csv:${i + 1}';
      tasks.add(
        TaskPlanDraft(
          id: taskId,
          dayOffset: offset,
          date: '',
          title: title,
          description: description,
          category: read(['Category'], 'Other'),
          priority: _priority(read(['Priority'], 'Medium')),
          durationMinutes: duration,
          completionCriteria: read([
            'Completion Criteria',
            'Outcome',
          ], description),
          dependencies: const [],
          sourceReference: 'CSV row ${i + 1}',
          suggested: false,
          visibility: _visibility(read(['Visibility'], 'Private')),
        ),
      );
      aliases[_header(read(['Task ID', 'ID'], taskId))] = taskId;
      aliases.putIfAbsent(_header(title), () => taskId);
      final dependency = read([
        'Depends On Task ID',
        'Dependency',
        'Dependencies',
      ]);
      if (dependency.isNotEmpty) dependenciesById[taskId] = dependency;
    }
    return tasks
        .map((task) {
          final dependency = dependenciesById[task.id];
          if (dependency == null) return task;
          final parent = aliases[_header(dependency)];
          if (parent == null) {
            return task.copyWith(dependencies: ['unresolved:$dependency']);
          }
          return task.copyWith(dependencies: [parent]);
        })
        .toList(growable: false);
  }

  List<TaskPlanDraft> _suggestFromBrief(
    _WorkbookBrief brief,
    DateTime start,
    int capacity,
    Map<String, int> occupiedMinutesByDate,
    List<String> warnings,
  ) {
    final topics = _splitTopics(brief.topics);
    if (brief.goal.trim().isEmpty || topics.isEmpty) return const [];
    warnings.add(
      'These are deterministic local suggestions based on the brief, not AI-verified requirements. Edit them before import.',
    );
    if (brief.deadline.trim().isNotEmpty) {
      warnings.add(
        'Review the source deadline: ${brief.deadline}. The planner does not assume it matches this 15-day window.',
      );
    }
    final unavailable = _unavailableDayOffsets(brief.unavailableDays, start);
    if (brief.unavailableDays.trim().isNotEmpty && unavailable.isEmpty) {
      warnings.add(
        'Unavailable days or commitments were found but could not be mapped to dates. Check and reassign tasks before importing.',
      );
    }
    if (brief.constraints.trim().isNotEmpty) {
      warnings.add(
        'Review the must-do constraints from the brief; suggestions do not automatically prove each constraint is satisfied.',
      );
    }
    const steps = [
      'Review and outline',
      'Study core material',
      'Write key notes',
      'Practice a small example',
      'Check understanding',
      'Apply the material',
      'Review and correct',
      'Build a working draft',
      'Test against requirements',
      'Address gaps',
      'Practice independently',
      'Review progress',
      'Complete a focused deliverable',
      'Verify the outcome',
      'Reflect and plan next steps',
    ];
    final availableDays = List.generate(
      15,
      (index) => index + 1,
    ).where((day) => !unavailable.contains(day)).toList(growable: false);
    if (availableDays.isEmpty) {
      throw const TaskPlanImportFailure(
        'All 15 days are marked unavailable. Adjust the Source Brief before generating a schedule.',
      );
    }
    final loads = <int, int>{};
    var latestDay = 0;
    return List.generate(15, (index) {
      final topic = topics[index % topics.length];
      final step = steps[index];
      final duration = min(30, capacity);
      final eligibleDays = availableDays.where(
        (candidate) => candidate >= latestDay && candidate >= index + 1,
      );
      var day = eligibleDays.firstWhere((candidate) {
        final date = _dateKey(start.add(Duration(days: candidate - 1)));
        return (occupiedMinutesByDate[date] ?? 0) +
                (loads[candidate] ?? 0) +
                duration <=
            capacity;
      }, orElse: () => 0);
      if (day == 0) {
        day = availableDays
            .where((candidate) => candidate >= latestDay)
            .firstWhere((candidate) {
              final date = _dateKey(start.add(Duration(days: candidate - 1)));
              return (occupiedMinutesByDate[date] ?? 0) +
                      (loads[candidate] ?? 0) +
                      duration <=
                  capacity;
            }, orElse: () => 0);
      }
      if (day == 0) {
        day =
            availableDays
                .where((candidate) => candidate >= latestDay)
                .firstOrNull ??
            availableDays.last;
      }
      latestDay = day;
      loads.update(day, (value) => value + duration, ifAbsent: () => duration);
      return TaskPlanDraft(
        id: 'suggestion:${index + 1}',
        dayOffset: day,
        date: '',
        title: '$step: $topic (Day ${index + 1})',
        description:
            'Suggested step toward: ${brief.goal.trim()}. Source topic: $topic.',
        category: 'Learning',
        priority: index == 0 || index == 14 ? 1 : 2,
        durationMinutes: duration,
        completionCriteria:
            'Record one concrete result or remaining question for $topic.',
        dependencies: index == 0 ? const [] : ['suggestion:$index'],
        sourceReference: 'Source Brief — $topic',
        suggested: true,
        visibility: RecordVisibility.private,
      );
    });
  }

  List<TaskPlanDraft> _suggestFromLines(
    String text,
    DateTime start,
    int capacity,
    String referenceType,
    Map<String, int> occupiedMinutesByDate,
    List<String> warnings,
  ) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map(
          (line) =>
              line.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+[.)])\s*'), '').trim(),
        )
        .where((line) => line.length >= 3)
        .toList();
    if (lines.isEmpty) {
      throw const TaskPlanImportFailure(
        'No readable text was extracted. Scanned/image-only or empty files are not supported.',
      );
    }
    warnings.add(
      'Extracted lines are task suggestions. Confirm their meaning and add measurable completion criteria where needed.',
    );
    if (lines.length < 15) {
      warnings.add(
        'The source has ${lines.length} usable lines; the planner creates 15 review suggestions by cycling the extracted material.',
      );
    }
    if (lines.length > 300) {
      throw const TaskPlanImportFailure(
        'This text contains more than 300 non-empty lines. Split the file so its preview stays reviewable.',
      );
    }
    final count = max(15, lines.length);
    final tasks = List.generate(count, (index) {
      final line = lines[index % lines.length];
      return TaskPlanDraft(
        id: 'extracted:${index + 1}',
        dayOffset: index % 15 + 1,
        date: '',
        title:
            '${line.length > 75 ? '${line.substring(0, 72)}…' : line} · Item ${index + 1}',
        description: line,
        category: 'Other',
        priority: 2,
        durationMinutes: min(30, capacity),
        completionCriteria: '',
        dependencies: const [],
        sourceReference: '$referenceType ${index % lines.length + 1}',
        suggested: true,
        visibility: RecordVisibility.private,
      );
    });
    return _placeSuggestions(tasks, start, capacity, occupiedMinutesByDate);
  }

  List<TaskPlanDraft> _suggestFromPages(
    List<String> pages,
    DateTime start,
    int capacity,
    Map<String, int> occupiedMinutesByDate,
    List<String> warnings,
  ) {
    if (pages.isEmpty || pages.every((page) => page.trim().isEmpty)) {
      throw const TaskPlanImportFailure(
        'No selectable PDF text was found. Scanned/image-only PDFs need OCR, which is not included.',
      );
    }
    final tasks = <TaskPlanDraft>[];
    for (var page = 0; page < pages.length; page++) {
      for (final line
          in pages[page]
              .split(RegExp(r'[\r\n]+'))
              .map((s) => s.trim())
              .where((s) => s.length >= 5)) {
        tasks.add(
          TaskPlanDraft(
            id: 'pdf:${tasks.length + 1}',
            dayOffset: tasks.length % 15 + 1,
            date: '',
            title:
                '${line.length > 75 ? '${line.substring(0, 72)}…' : line} · Page ${page + 1}, item ${tasks.length + 1}',
            description: line,
            category: 'Other',
            priority: 2,
            durationMinutes: min(30, capacity),
            completionCriteria: '',
            dependencies: const [],
            sourceReference: 'PDF page ${page + 1}',
            suggested: true,
            visibility: RecordVisibility.private,
          ),
        );
      }
    }
    if (tasks.isEmpty) {
      throw const TaskPlanImportFailure(
        'The PDF has no extractable text. Scanned/image-only PDFs are not supported.',
      );
    }
    warnings.add(
      'PDF text extraction preserves page references; extracted lines are suggestions and may lose table or column structure. Review before import.',
    );
    _assignGeneratedDependencies(tasks);
    return _placeSuggestions(tasks, start, capacity, occupiedMinutesByDate);
  }

  List<String> _extractDocxParagraphs(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final doc = archive.findFile('word/document.xml');
      if (doc == null || !doc.isFile) {
        throw const TaskPlanImportFailure(
          'The DOCX is missing its document body.',
        );
      }
      final xml = XmlDocument.parse(utf8.decode(doc.readBytes()!));
      final ns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
      return xml
          .findAllElements('p', namespace: ns)
          .map(
            (p) => p
                .findAllElements('t', namespace: ns)
                .map((t) => t.innerText)
                .join(),
          )
          .where((text) => text.trim().isNotEmpty)
          .toList(growable: false);
    } on TaskPlanImportFailure {
      rethrow;
    } on Object {
      throw const TaskPlanImportFailure(
        'Could not read this DOCX. Confirm it is a valid, unencrypted Word document.',
      );
    }
  }

  static void _assignGeneratedDependencies(List<TaskPlanDraft> tasks) {
    for (var i = 1; i < tasks.length; i++) {
      if (tasks[i].dependencies.isEmpty) {
        tasks[i] = tasks[i].copyWith(dependencies: [tasks[i - 1].id]);
      }
    }
  }

  static void _validateDependencies(List<TaskPlanDraft> tasks) {
    final byId = {for (final task in tasks) task.id: task};
    final indexById = {for (var i = 0; i < tasks.length; i++) tasks[i].id: i};
    for (var currentIndex = 0; currentIndex < tasks.length; currentIndex++) {
      final task = tasks[currentIndex];
      if (task.title.trim().isEmpty) {
        throw const TaskPlanImportFailure('Every task needs a title.');
      }
      if (task.dayOffset < 1 ||
          task.dayOffset > 15 ||
          task.durationMinutes < 1 ||
          task.durationMinutes > 1440 ||
          task.priority < 1 ||
          task.priority > 3) {
        throw TaskPlanImportFailure(
          'Task "${task.title}" has an invalid day, priority, or duration.',
        );
      }
      for (final dependency in task.dependencies) {
        final prerequisite = byId[dependency];
        if (prerequisite == null) {
          throw TaskPlanImportFailure(
            'Task "${task.title}" has an unresolved dependency "$dependency".',
          );
        }
        final prerequisiteIndex = indexById[dependency]!;
        if (prerequisite.dayOffset > task.dayOffset ||
            (prerequisite.dayOffset == task.dayOffset &&
                prerequisiteIndex >= currentIndex)) {
          throw TaskPlanImportFailure(
            'Task "${task.title}" is scheduled before its prerequisite.',
          );
        }
      }
    }
  }

  static void _validateDuplicates(List<TaskPlanDraft> tasks) {
    final seen = <String>{};
    for (final task in tasks) {
      final key = '${task.dayOffset}:${_header(task.title)}';
      if (!seen.add(key)) {
        throw TaskPlanImportFailure(
          'Duplicate task "${task.title}" appears more than once on Day ${task.dayOffset}.',
        );
      }
    }
  }

  static void _checkCapacity(
    List<TaskPlanDraft> tasks,
    int capacity,
    List<String> warnings,
    Map<String, int> occupiedMinutesByDate,
    DateTime startDate,
  ) {
    final totals = <int, int>{};
    for (final task in tasks) {
      totals.update(
        task.dayOffset,
        (value) => value + task.durationMinutes,
        ifAbsent: () => task.durationMinutes,
      );
    }
    for (final entry in totals.entries.where((e) => e.value > capacity)) {
      warnings.add(
        'Day ${entry.key} is ${entry.value - capacity} minutes over the available $capacity-minute daily limit. Reassign or reduce tasks.',
      );
    }
    for (final entry in totals.entries) {
      final date = _dateKey(startDate.add(Duration(days: entry.key - 1)));
      final existing = occupiedMinutesByDate[date] ?? 0;
      final combined = existing + entry.value;
      if (combined > capacity) {
        warnings.add(
          'Day ${entry.key} has $existing minutes of existing commitments plus ${entry.value} imported minutes, exceeding the $capacity-minute daily limit by ${combined - capacity} minutes. Reassign or reduce tasks.',
        );
      }
    }
  }
}

Set<int> _unavailableDayOffsets(String input, DateTime start) {
  final days = <int>{};
  for (final match in RegExp(
    r'\bday\s*(\d{1,2})\b',
    caseSensitive: false,
  ).allMatches(input)) {
    final day = int.parse(match[1]!);
    if (day >= 1 && day <= 15) days.add(day);
  }
  for (final match in RegExp(r'\b(\d{4}-\d{2}-\d{2})\b').allMatches(input)) {
    final date = _parseDate(match[1]);
    if (date == null) continue;
    final offset =
        date.difference(DateTime(start.year, start.month, start.day)).inDays +
        1;
    if (offset >= 1 && offset <= 15) days.add(offset);
  }
  return days;
}

Map<String, int> _occupancy(
  DateTime start,
  Map<String, int> supplied,
  List<TaskPlanCommitment> commitments,
) {
  final result = Map<String, int>.from(supplied);
  for (var offset = 0; offset < 15; offset++) {
    final date = start.add(Duration(days: offset));
    final key = _dateKey(date);
    final existing = commitments
        .where((commitment) => commitment.occursOn(date))
        .fold<int>(
          0,
          (total, commitment) => total + commitment.durationMinutes,
        );
    result.update(key, (value) => value + existing, ifAbsent: () => existing);
  }
  return result;
}

List<TaskPlanDraft> _placeSuggestions(
  List<TaskPlanDraft> tasks,
  DateTime start,
  int capacity,
  Map<String, int> occupiedMinutesByDate,
) {
  final loads = <int, int>{};
  return tasks
      .asMap()
      .entries
      .map((entry) {
        final task = entry.value;
        final preferredDay = ((task.dayOffset - 1) % 15) + 1;
        final candidates = List.generate(
          15,
          (index) => ((preferredDay - 1 + index) % 15) + 1,
        );
        var day = candidates.firstWhere((candidate) {
          final date = _dateKey(start.add(Duration(days: candidate - 1)));
          return (occupiedMinutesByDate[date] ?? 0) +
                  (loads[candidate] ?? 0) +
                  task.durationMinutes <=
              capacity;
        }, orElse: () => 0);
        if (day == 0) {
          day = List.generate(15, (i) => i + 1).firstWhere((candidate) {
            final date = _dateKey(start.add(Duration(days: candidate - 1)));
            return (occupiedMinutesByDate[date] ?? 0) +
                    (loads[candidate] ?? 0) +
                    task.durationMinutes <=
                capacity;
          }, orElse: () => 0);
        }
        if (day == 0) {
          day = candidates.reduce((leastLoaded, candidate) {
            final candidateDate = _dateKey(
              start.add(Duration(days: candidate - 1)),
            );
            final leastDate = _dateKey(
              start.add(Duration(days: leastLoaded - 1)),
            );
            final candidateLoad =
                (occupiedMinutesByDate[candidateDate] ?? 0) +
                (loads[candidate] ?? 0);
            final leastLoad =
                (occupiedMinutesByDate[leastDate] ?? 0) +
                (loads[leastLoaded] ?? 0);
            return candidateLoad < leastLoad ? candidate : leastLoaded;
          });
        }
        loads.update(
          day,
          (value) => value + task.durationMinutes,
          ifAbsent: () => task.durationMinutes,
        );
        return task.copyWith(dayOffset: day);
      })
      .toList(growable: false);
}

String _decodeText(Uint8List bytes) {
  try {
    return utf8.decode(bytes, allowMalformed: false);
  } on FormatException {
    throw const TaskPlanImportFailure(
      'The text file is not valid UTF-8. Save it as UTF-8 and try again.',
    );
  }
}

abstract interface class PdfTextExtractor {
  Future<List<String>> extractPages(Uint8List bytes);
}

class LocalPdfTextExtractor implements PdfTextExtractor {
  const LocalPdfTextExtractor();

  @override
  Future<List<String>> extractPages(Uint8List bytes) async {
    final temp = await Directory.systemTemp.createTemp('life_os_pdf_');
    final file = File('${temp.path}${Platform.pathSeparator}source.pdf');
    try {
      await file.writeAsBytes(bytes, flush: true);
      final doc = await PDFDoc.fromFile(file);
      final pages = <String>[];
      for (final page in doc.pages) {
        pages.add(await page.text);
      }
      return pages;
    } on Object {
      throw const TaskPlanImportFailure(
        'Could not extract PDF text. The file may be encrypted, damaged, or unsupported.',
      );
    } finally {
      try {
        await temp.delete(recursive: true);
      } on Object {
        // Temporary source content is best-effort removed even after a parser error.
      }
    }
  }
}

class _WorkbookBrief {
  const _WorkbookBrief({
    required this.goal,
    required this.topics,
    required this.deadline,
    required this.unavailableDays,
    required this.constraints,
    required this.startDate,
    required this.capacity,
    required this.tasks,
  });
  final String goal, topics, deadline, unavailableDays, constraints;
  final DateTime? startDate;
  final int? capacity;
  final List<TaskPlanDraft> tasks;
}

int _columnIndex(String reference) {
  var value = 0;
  for (final code in reference.toUpperCase().codeUnits) {
    if (code < 65 || code > 90) break;
    value = value * 26 + code - 64;
  }
  return value - 1;
}

String _header(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
String _nonEmpty(String? value, String fallback) =>
    value == null || value.trim().isEmpty ? fallback : value.trim();
int? _optionalInt(String? value) => value == null || value.trim().isEmpty
    ? null
    : double.tryParse(value.trim())?.round();
int _priority(String? value) => switch ((value ?? '').trim().toLowerCase()) {
  'high' => 1,
  'low' => 3,
  _ => 2,
};
RecordVisibility _visibility(String? value) =>
    (value ?? '').trim().toLowerCase() == 'shared'
    ? RecordVisibility.shared
    : RecordVisibility.private;
int _parsePreferredTime(String? value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value?.trim() ?? '');
  if (match == null) return 540;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  return hour < 24 && minute < 60 ? hour * 60 + minute : 540;
}

DateTime? _parseDate(String? input) {
  final value = input?.trim() ?? '';
  final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (iso != null) {
    final date = DateTime(
      int.parse(iso[1]!),
      int.parse(iso[2]!),
      int.parse(iso[3]!),
    );
    if (date.year == int.parse(iso[1]!) &&
        date.month == int.parse(iso[2]!) &&
        date.day == int.parse(iso[3]!)) {
      return date;
    }
  }
  final serial = int.tryParse(value);
  if (serial != null && serial > 0 && serial < 100000) {
    return DateTime(1899, 12, 30).add(Duration(days: serial));
  }
  return null;
}

List<String> _splitTopics(String input) => input
    .split(RegExp(r'[\r\n;,]+'))
    .map((v) => v.trim())
    .where((v) => v.isNotEmpty)
    .toList(growable: false);
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
