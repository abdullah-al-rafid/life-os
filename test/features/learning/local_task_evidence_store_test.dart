import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/learning/data/local_task_evidence_store.dart';

void main() {
  late Directory root;
  late LocalTaskEvidenceStore store;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('life_os_evidence_test_');
    store = LocalTaskEvidenceStore(root: root);
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'stores evidence in the authenticated UID folder and reads it only there',
    () async {
      final evidence = await store.save(
        ownerUid: 'uid-a',
        name: 'notes.txt',
        bytes: Uint8List.fromList('learning notes'.codeUnits),
      );
      expect(evidence.name, 'notes.txt');
      expect(
        await store.read(ownerUid: 'uid-a', key: evidence.key),
        'learning notes'.codeUnits,
      );
      await expectLater(
        store.read(ownerUid: 'uid-b', key: evidence.key),
        throwsA(isA<TaskEvidenceFailure>()),
      );
      await store.delete(ownerUid: 'uid-a', key: evidence.key);
      await expectLater(
        store.read(ownerUid: 'uid-a', key: evidence.key),
        throwsA(isA<TaskEvidenceFailure>()),
      );
    },
  );

  test(
    'rejects unsupported extensions, mismatched content, oversized data and unsafe references',
    () async {
      await expectLater(
        store.save(
          ownerUid: 'uid-a',
          name: 'evidence.exe',
          bytes: Uint8List.fromList([1]),
        ),
        throwsA(isA<TaskEvidenceFailure>()),
      );
      await expectLater(
        store.save(
          ownerUid: 'uid-a',
          name: 'fake.pdf',
          bytes: Uint8List.fromList('not a PDF'.codeUnits),
        ),
        throwsA(isA<TaskEvidenceFailure>()),
      );
      await expectLater(
        store.save(
          ownerUid: 'uid-a',
          name: 'large.txt',
          bytes: Uint8List(taskEvidenceMaxBytes + 1),
        ),
        throwsA(isA<TaskEvidenceFailure>()),
      );
      await expectLater(
        store.read(ownerUid: 'uid-a', key: '../uid-b/file.txt'),
        throwsA(isA<TaskEvidenceFailure>()),
      );
      await expectLater(
        store.save(
          ownerUid: '../uid-b',
          name: 'ok.txt',
          bytes: Uint8List.fromList([65]),
        ),
        throwsA(isA<TaskEvidenceFailure>()),
      );
    },
  );
}
