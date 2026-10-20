import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/planning/domain/task_plan_import.dart';

void main() {
  final importer = TaskPlanImporter(pdfTextExtractor: _FakePdfTextExtractor());
  final start = DateTime(2026, 10, 14);

  test(
    'reads the supplied template schema and rejects its intentionally blank brief',
    () async {
      final file = File(
        'docs/templates/LIFE_OS_15_Day_Task_Import_Template.xlsx',
      );
      final bytes = await file.readAsBytes();
      await expectLater(
        importer.parse(
          fileName: file.path.split('/').last,
          bytes: bytes,
          startDate: start,
        ),
        throwsA(isA<TaskPlanImportFailure>()),
      );
    },
  );

  test(
    'parses XLSX headings, rows, day offsets, defaults and dependencies',
    () async {
      final bytes = _xlsx();
      final proposal = await importer.parse(
        fileName: 'plan.xlsx',
        bytes: bytes,
        startDate: start,
      );
      expect(proposal.tasks, hasLength(2));
      expect(proposal.tasks.first.title, 'Read chapter one');
      expect(proposal.tasks.first.date, '2026-10-14');
      expect(proposal.tasks.last.date, '2026-10-15');
      expect(proposal.tasks.last.dependencies, [proposal.tasks.first.id]);
      expect(proposal.dates, hasLength(15));
      expect(proposal.tasks.last.visibility.name, 'private');
    },
  );

  test(
    'XLSX non-numeric task duration is rejected instead of defaulted',
    () async {
      await expectLater(
        importer.parse(
          fileName: 'invalid-duration.xlsx',
          bytes: _xlsx(firstDuration: '30.5'),
          startDate: start,
        ),
        throwsA(
          isA<TaskPlanImportFailure>().having(
            (failure) => failure.message,
            'message',
            contains('non-numeric estimate'),
          ),
        ),
      );
    },
  );

  test(
    'CSV schedules multiple tasks on the same day and warns on overload',
    () async {
      final csv = utf8.encode(
        'Task Title,Day Offset,Estimated Minutes,Priority,Category\nRead,1,40,High,Study\nPractice,1,40,Medium,Study',
      );
      final proposal = await importer.parse(
        fileName: 'plan.csv',
        bytes: csv,
        startDate: start,
        dailyCapacityMinutes: 60,
      );
      expect(proposal.tasks, hasLength(2));
      expect(proposal.tasks.map((task) => task.dayOffset).toSet(), {1});
      expect(proposal.warnings.join(), contains('exceeding'));
      expect(proposal.tasks.first.priority, 1);
    },
  );

  test(
    'reads the supplied LIFE OS CSV headers without losing day or fields',
    () async {
      final bytes = utf8.encode(
        'plan_day,task_id,title,description,category,priority,estimated_minutes,preferred_time,depends_on,completion_criteria,evidence_required,source_reference\n'
        '1,D01-T01,First task,Description,Learning,High,45,Morning,,Done,optional,Book\n'
        '2,D02-T01,Second task,Details,Learning,Medium,60,Afternoon,D01-T01,Result,required,Course',
      );
      final proposal = await importer.parse(
        fileName: 'LIFE_OS_15_Day_Task_Plan.csv',
        bytes: bytes,
        startDate: start,
      );
      expect(proposal.tasks.map((task) => task.dayOffset), [1, 2]);
      expect(proposal.tasks.map((task) => task.title), [
        'First task',
        'Second task',
      ]);
      expect(proposal.tasks.map((task) => task.durationMinutes), [45, 60]);
      expect(proposal.tasks.first.priority, 1);
      expect(proposal.tasks.first.scheduledMinute, 540);
      expect(proposal.tasks.last.scheduledMinute, 840);
      expect(proposal.tasks.last.sourceReference, 'Course');
      expect(proposal.tasks.last.dependencies, [proposal.tasks.first.id]);
      expect(proposal.tasks.last.completionCriteria, 'Result');
      expect(
        proposal.warnings.where((warning) => warning.contains('no day column')),
        isEmpty,
      );
    },
  );

  test(
    'resolves every semicolon-separated dependency in the supplied CSV format',
    () async {
      final bytes = utf8.encode(
        'plan_day,task_id,title,description,category,priority,estimated_minutes,preferred_time,depends_on,completion_criteria,evidence_required,source_reference\n'
        '14,D14-T01,Complete retrospective,Review outcomes,LIFE OS,High,30,Morning,,Retrospective complete,optional,Review\n'
        '14,D14-T03,Select carry-over tasks,Choose unfinished tasks,LIFE OS,Medium,30,Afternoon,,Tasks selected,optional,Review\n'
        '15,D15-T01,Complete 15-day retrospective,Review all days,LIFE OS,High,30,Morning,D14-T01,Retrospective complete,optional,Review\n'
        '15,D15-T02,Draft the next cycle priorities,Choose outcomes,Personal,High,30,Afternoon,D14-T03,Priorities drafted,optional,Next plan\n'
        '15,D15-T03,Finalize and approve next-plan input,Prepare next source plan,LIFE OS,High,45,Evening,D15-T01;D15-T02,Input approved,optional,Next plan',
      );
      final proposal = await importer.parse(
        fileName: 'LIFE_OS_15_Day_Task_Plan.csv',
        bytes: bytes,
        startDate: start,
        dailyCapacityMinutes: 120,
      );

      final retrospective = proposal.tasks.singleWhere(
        (task) => task.id == 'csv:4',
      );
      final priorities = proposal.tasks.singleWhere(
        (task) => task.id == 'csv:5',
      );
      final finalInput = proposal.tasks.singleWhere(
        (task) => task.id == 'csv:6',
      );
      expect(finalInput.dependencies, [retrospective.id, priorities.id]);
      expect(
        finalInput.dependencies.every(
          (dependency) => !dependency.startsWith('unresolved:'),
        ),
        isTrue,
      );
    },
  );

  test(
    'CSV without day column distributes tasks within 120 minutes when feasible',
    () async {
      final bytes = utf8.encode(
        'task_id,title,estimated_minutes\n'
        'a,Task A,60\n'
        'b,Task B,60\n'
        'c,Task C,60\n'
        'd,Task D,60',
      );
      final proposal = await importer.parse(
        fileName: 'undated.csv',
        bytes: bytes,
        startDate: start,
        dailyCapacityMinutes: 120,
      );
      expect(proposal.tasks, hasLength(4));
      expect(proposal.tasks.map((task) => task.dayOffset), [1, 2, 3, 4]);
      expect(
        proposal.warnings.where((warning) => warning.contains('exceeding')),
        isEmpty,
      );
    },
  );

  test('120 minute CSV capacity reports each overloaded day once', () async {
    final bytes = utf8.encode(
      'plan_day,title,estimated_minutes\n'
      '1,Task A,70\n1,Task B,70\n2,Task C,130',
    );
    final proposal = await importer.parse(
      fileName: 'overloaded.csv',
      bytes: bytes,
      startDate: start,
      dailyCapacityMinutes: 120,
    );
    final capacityWarnings = proposal.warnings
        .where((warning) => warning.contains('exceeding'))
        .toList();
    expect(capacityWarnings, hasLength(2));
    expect(capacityWarnings.join('\n'), contains('Day 1'));
    expect(capacityWarnings.join('\n'), contains('Day 2'));
    expect(proposal.tasks, hasLength(3));
  });

  test('capacity boundary accepts 120 and warns at 121 minutes', () async {
    final exact = await importer.parse(
      fileName: 'exact.csv',
      bytes: utf8.encode(
        'plan_day,title,estimated_minutes\n1,Exactly full,120',
      ),
      startDate: start,
      dailyCapacityMinutes: 120,
    );
    expect(exact.overloadedDays, isEmpty);
    expect(exact.taskMinutesByDay[1], 120);

    final over = await importer.parse(
      fileName: 'over.csv',
      bytes: utf8.encode('plan_day,title,estimated_minutes\n1,One over,121'),
      startDate: start,
      dailyCapacityMinutes: 120,
    );
    expect(over.overloadedDays, [1]);
    expect(over.tasks, hasLength(1));
  });

  test(
    'date column maps day 1 and day 15 and rejects outside the cycle',
    () async {
      final proposal = await importer.parse(
        fileName: 'date-column.csv',
        bytes: utf8.encode(
          'task_date,title,estimated_minutes\n'
          '2026-10-14,First day,10\n'
          '2026-10-28,Last day,10',
        ),
        startDate: start,
      );
      expect(proposal.tasks.map((task) => task.dayOffset), [1, 15]);
      expect(proposal.tasks.map((task) => task.date), [
        '2026-10-14',
        '2026-10-28',
      ]);

      await expectLater(
        importer.parse(
          fileName: 'outside.csv',
          bytes: utf8.encode('task_date,title\n2026-10-29,Outside the cycle'),
          startDate: start,
        ),
        throwsA(
          isA<TaskPlanImportFailure>().having(
            (failure) => failure.message,
            'message',
            contains('outside 1–15'),
          ),
        ),
      );
    },
  );

  test(
    'existing fixed commitments affect automatic placement and overloads',
    () async {
      final commitment = TaskPlanCommitment(
        recurrence: 'once',
        scheduledDate: '2026-10-14',
        durationMinutes: 120,
      );
      final bytes = utf8.encode('title,estimated_minutes\nTask,30');
      final placed = await importer.parse(
        fileName: 'automatic.csv',
        bytes: bytes,
        startDate: start,
        dailyCapacityMinutes: 120,
        existingCommitments: [commitment],
      );
      expect(placed.tasks.single.dayOffset, 2);
      expect(placed.existingMinutesOnDay(1), 120);

      final overloaded = await importer.parse(
        fileName: 'fixed.csv',
        bytes: utf8.encode('plan_day,title,estimated_minutes\n1,Task,31'),
        startDate: start,
        dailyCapacityMinutes: 120,
        existingCommitments: [
          TaskPlanCommitment(
            recurrence: 'once',
            scheduledDate: '2026-10-14',
            durationMinutes: 90,
          ),
        ],
      );
      expect(overloaded.overloadedDays, [1]);
      expect(overloaded.totalMinutesOnDay(1), 121);
      expect(
        overloaded.warnings.where((warning) => warning.contains('Day 1')),
        hasLength(1),
      );
    },
  );

  test('preview reassignments refresh dates, workload and warnings', () async {
    final proposal = await importer.parse(
      fileName: 'editable.csv',
      bytes: utf8.encode(
        'plan_day,title,estimated_minutes\n1,First,90\n2,Second,40',
      ),
      startDate: start,
      dailyCapacityMinutes: 120,
    );
    final moved = proposal.withTasks([
      proposal.tasks.first,
      proposal.tasks.last.copyWith(dayOffset: 1, title: 'Edited second task'),
    ]);
    expect(moved.tasks.last.title, 'Edited second task');
    expect(moved.tasks.last.dayOffset, 1);
    expect(moved.tasks.last.date, '2026-10-14');
    expect(moved.taskMinutesByDay[1], 130);
    expect(moved.overloadedDays, [1]);
    expect(
      moved.warnings.where((warning) => warning.contains('exceeding')),
      hasLength(1),
    );
  });

  test(
    'CSV invalid dates, missing titles and invalid durations fail clearly',
    () async {
      Future<void> reject(String csvText, String expected) async {
        await expectLater(
          importer.parse(
            fileName: 'invalid.csv',
            bytes: utf8.encode(csvText),
            startDate: start,
          ),
          throwsA(
            isA<TaskPlanImportFailure>().having(
              (failure) => failure.message,
              'message',
              contains(expected),
            ),
          ),
        );
      }

      await reject('date,title\n2026-02-30,Task', 'invalid date');
      await reject('plan_day,title\n,Task', 'invalid day/date');
      await reject('plan_day,title,estimated_minutes\n1,,20', 'no task title');
      await reject(
        'plan_day,title,estimated_minutes\n1,Task,twenty',
        'non-numeric duration',
      );
      await reject(
        'plan_day,title,estimated_minutes\n1,Task,0',
        'invalid duration',
      );
      await reject(
        'plan_day,date,title\n1,2026-10-15,Task',
        'conflicting day and date',
      );
    },
  );

  test('ambiguous dependencies and malformed times are rejected', () async {
    await expectLater(
      importer.parse(
        fileName: 'ambiguous.csv',
        bytes: utf8.encode(
          'plan_day,title,estimated_minutes,task_id,depends_on\n'
          '1,Prepare,20,a,\n'
          '2,Prepare,20,b,\n'
          '3,Finish,20,c,Prepare',
        ),
        startDate: start,
      ),
      throwsA(
        isA<TaskPlanImportFailure>().having(
          (failure) => failure.message,
          'message',
          contains('matches multiple task titles'),
        ),
      ),
    );
    await expectLater(
      importer.parse(
        fileName: 'time.csv',
        bytes: utf8.encode(
          'plan_day,title,estimated_minutes,preferred_time\n1,Task,20,25:99',
        ),
        startDate: start,
      ),
      throwsA(
        isA<TaskPlanImportFailure>().having(
          (failure) => failure.message,
          'message',
          contains('invalid preferred time'),
        ),
      ),
    );
  });

  test(
    'preferred-time overlap is surfaced and clears after preview edit',
    () async {
      final proposal = await importer.parse(
        fileName: 'time-overlap.csv',
        bytes: utf8.encode(
          'plan_day,title,estimated_minutes,preferred_time\n'
          '1,First session,60,09:00\n'
          '1,Second session,30,09:30',
        ),
        startDate: start,
      );
      expect(proposal.scheduleConflicts, hasLength(1));
      expect(proposal.warnings, contains(proposal.scheduleConflicts.single));
      final edited = proposal.withTasks([
        proposal.tasks.first,
        proposal.tasks.last.copyWith(scheduledMinute: 600),
      ]);
      expect(edited.scheduleConflicts, isEmpty);
      expect(
        edited.warnings.where(
          (warning) => warning.startsWith('Preferred time conflict:'),
        ),
        isEmpty,
      );
      final crossesMidnight = await importer.parse(
        fileName: 'midnight.csv',
        bytes: utf8.encode(
          'plan_day,title,estimated_minutes,preferred_time\n1,Late task,60,23:30',
        ),
        startDate: start,
      );
      expect(
        crossesMidnight.validateForApproval,
        throwsA(isA<TaskPlanImportFailure>()),
      );
    },
  );

  test(
    'duplicate headers, IDs, tasks and out-of-order dependencies fail',
    () async {
      for (final csvText in [
        'plan_day,day,title\n1,1,Task',
        'plan_day,title,task_id\n1,First,x\n2,Second,x',
        'plan_day,title\n1,Same title\n1,Same title',
        'plan_day,title,depends_on\n1,Child,Parent\n1,Parent,',
      ]) {
        await expectLater(
          importer.parse(
            fileName: 'conflict.csv',
            bytes: utf8.encode(csvText),
            startDate: start,
          ),
          throwsA(isA<TaskPlanImportFailure>()),
        );
      }
    },
  );

  test(
    'TXT generates 15 clearly marked local suggestions and a full date range',
    () async {
      final proposal = await importer.parse(
        fileName: 'notes.txt',
        bytes: utf8.encode('Algebra\nGeometry\nStatistics'),
        startDate: start,
      );
      expect(proposal.tasks, hasLength(15));
      expect(proposal.tasks.every((task) => task.suggested), isTrue);
      expect(proposal.tasks.first.date, '2026-10-14');
      expect(proposal.tasks.last.date, '2026-10-28');
      expect(proposal.warnings, isNotEmpty);
    },
  );

  test(
    'long TXT sources retain all tasks and report workload overflow',
    () async {
      final lines = List.generate(
        20,
        (index) => 'Source requirement ${index + 1}',
      );
      final proposal = await importer.parse(
        fileName: 'requirements.txt',
        bytes: utf8.encode(lines.join('\n')),
        startDate: start,
        dailyCapacityMinutes: 30,
      );
      expect(proposal.tasks, hasLength(20));
      expect(
        proposal.tasks.map((task) => task.dayOffset).toSet(),
        containsAll(List.generate(15, (index) => index + 1)),
      );
      expect(proposal.tasks.every((task) => task.dependencies.isEmpty), isTrue);
      expect(proposal.warnings.join(), contains('exceeding'));
    },
  );

  test('DOCX extraction preserves paragraph source references', () async {
    final proposal = await importer.parse(
      fileName: 'notes.docx',
      bytes: _docx(),
      startDate: start,
    );
    expect(proposal.tasks, hasLength(15));
    expect(proposal.tasks.first.sourceReference, 'Paragraph 1');
  });

  test(
    'PDF extraction preserves page references and flags uncertain structure',
    () async {
      final proposal = await importer.parse(
        fileName: 'notes.pdf',
        bytes: Uint8List.fromList([37, 80, 68, 70]),
        startDate: start,
      );
      expect(proposal.tasks.first.sourceReference, 'PDF page 1');
      expect(proposal.warnings.join(), contains('table or column structure'));
    },
  );

  test(
    'rejects empty, oversized, unsupported, malformed and empty-text input',
    () async {
      await expectLater(
        importer.parse(fileName: 'empty.txt', bytes: Uint8List(0)),
        throwsA(isA<TaskPlanImportFailure>()),
      );
      await expectLater(
        importer.parse(
          fileName: 'large.txt',
          bytes: Uint8List(taskPlanMaxFileBytes + 1),
        ),
        throwsA(isA<TaskPlanImportFailure>()),
      );
      await expectLater(
        importer.parse(fileName: 'image.png', bytes: Uint8List.fromList([1])),
        throwsA(isA<TaskPlanImportFailure>()),
      );
      await expectLater(
        importer.parse(
          fileName: 'bad.csv',
          bytes: utf8.encode('Description\nabc'),
        ),
        throwsA(isA<TaskPlanImportFailure>()),
      );
      await expectLater(
        importer.parse(fileName: 'blank.pdf', bytes: Uint8List.fromList([1])),
        throwsA(isA<TaskPlanImportFailure>()),
      );
      await expectLater(
        importer.parse(
          fileName: 'malformed.xlsx',
          bytes: utf8.encode('not a zip'),
        ),
        throwsA(isA<TaskPlanImportFailure>()),
      );
    },
  );
}

Uint8List _xlsx({String firstDuration = '30'}) {
  const ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  const relNs =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  String cells(List<String> values, int row) => values.indexed.map((entry) {
    final col = String.fromCharCode(65 + entry.$1);
    return '<c r="$col$row" t="inlineStr"><is><t>${entry.$2}</t></is></c>';
  }).join();
  final tasks =
      '''<worksheet xmlns="$ns"><sheetData>
    <row r="4">${cells(['Day Offset (1-15)', 'Task Title *', 'Description / Outcome', 'Category', 'Priority', 'Estimated Minutes', 'Preferred Time', 'Depends on Task ID', 'Visibility', 'Source Reference', 'Notes'], 4)}</row>
    <row r="5">${cells(['1', 'Read chapter one', 'Summarize three ideas', 'Study', 'High', firstDuration, '09:30', '', 'Private', '', ''], 5)}</row>
    <row r="6">${cells(['2', 'Practice chapter one', 'Solve exercises', 'Study', 'Medium', '45', '', 'Read chapter one', 'Private', '', ''], 6)}</row>
    </sheetData></worksheet>''';
  final brief =
      '''<worksheet xmlns="$ns"><sheetData>
    <row r="4">${cells(['Main goal / desired outcome', 'Learn the topic'], 4)}</row>
    </sheetData></worksheet>''';
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'xl/workbook.xml',
        '<workbook xmlns="$ns" xmlns:r="$relNs"><sheets><sheet name="Tasks" sheetId="1" r:id="rId1"/><sheet name="Source Brief" sheetId="2" r:id="rId2"/></sheets></workbook>',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Target="worksheets/sheet2.xml"/></Relationships>',
      ),
    )
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', tasks))
    ..addFile(ArchiveFile.string('xl/worksheets/sheet2.xml', brief));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Uint8List _docx() {
  const ns = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';
  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        'word/document.xml',
        '<document xmlns:w="$ns"><body><w:p><w:r><w:t>Read the lesson</w:t></w:r></w:p></body></document>',
      ),
    );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

class _FakePdfTextExtractor implements PdfTextExtractor {
  @override
  Future<List<String>> extractPages(Uint8List bytes) async => bytes.length == 1
      ? const ['']
      : const ['Read the source overview', 'Practice the main example'];
}
