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
      expect(proposal.warnings.join(), contains('over the available'));
      expect(proposal.tasks.first.priority, 1);
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
      expect(proposal.warnings.join(), contains('over the available'));
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

Uint8List _xlsx() {
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
    <row r="5">${cells(['1', 'Read chapter one', 'Summarize three ideas', 'Study', 'High', '30', '09:30', '', 'Private', '', ''], 5)}</row>
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
