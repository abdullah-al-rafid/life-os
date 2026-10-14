import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const taskEvidenceMaxBytes = 10 * 1024 * 1024;
const _allowedEvidenceExtensions = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'pdf',
  'txt',
  'docx',
};

class LocalTaskEvidence {
  const LocalTaskEvidence({
    required this.key,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.addedAtUtc,
  });
  final String key;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime addedAtUtc;

  Map<String, Object?> toJson() => {
    'key': key,
    'name': name,
    'extension': extension,
    'sizeBytes': sizeBytes,
    'addedAtUtc': addedAtUtc.toIso8601String(),
  };
}

class LocalTaskEvidenceStore {
  LocalTaskEvidenceStore({Directory? root, Random? random})
    : _root = root,
      _random = random ?? Random.secure();
  final Directory? _root;
  final Random _random;

  Future<LocalTaskEvidence> save({
    required String ownerUid,
    required String name,
    required Uint8List bytes,
    DateTime? now,
  }) async {
    _validateUid(ownerUid);
    if (bytes.isEmpty || bytes.length > taskEvidenceMaxBytes) {
      throw const TaskEvidenceFailure(
        'Evidence must be between 1 byte and 10 MB.',
      );
    }
    final extension = p.extension(name).replaceFirst('.', '').toLowerCase();
    if (!_allowedEvidenceExtensions.contains(extension)) {
      throw const TaskEvidenceFailure(
        'Choose a JPG, PNG, WebP, PDF, TXT, or DOCX file.',
      );
    }
    if (!_contentMatches(extension, bytes)) {
      throw const TaskEvidenceFailure(
        'The selected file content does not match its file type.',
      );
    }
    final directory = Directory(
      p.join((await _supportDirectory()).path, 'life_os', 'evidence', ownerUid),
    );
    await directory.create(recursive: true);
    final key =
        '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32).toRadixString(16)}.$extension';
    final file = File(p.join(directory.path, key));
    try {
      await file.writeAsBytes(bytes, flush: true);
      return LocalTaskEvidence(
        key: key,
        name: p.basename(name),
        extension: extension,
        sizeBytes: bytes.length,
        addedAtUtc: (now ?? DateTime.now().toUtc()).toUtc(),
      );
    } on Object {
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    }
  }

  Future<Uint8List> read({
    required String ownerUid,
    required String key,
  }) async {
    _validateUid(ownerUid);
    if (p.basename(key) != key || key.contains('..')) {
      throw const TaskEvidenceFailure('Evidence reference is invalid.');
    }
    final file = File(
      p.join(
        (await _supportDirectory()).path,
        'life_os',
        'evidence',
        ownerUid,
        key,
      ),
    );
    if (!await file.exists()) {
      throw const TaskEvidenceFailure(
        'This local evidence file is unavailable.',
      );
    }
    return file.readAsBytes();
  }

  Future<void> delete({required String ownerUid, required String key}) async {
    _validateUid(ownerUid);
    if (p.basename(key) != key || key.contains('..')) {
      throw const TaskEvidenceFailure('Evidence reference is invalid.');
    }
    final file = File(
      p.join(
        (await _supportDirectory()).path,
        'life_os',
        'evidence',
        ownerUid,
        key,
      ),
    );
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _supportDirectory() async =>
      _root ?? await getApplicationSupportDirectory();
  void _validateUid(String uid) {
    if (uid.isEmpty || !RegExp(r'^[A-Za-z0-9:_-]+$').hasMatch(uid)) {
      throw const TaskEvidenceFailure(
        'Authenticated account identifier is invalid.',
      );
    }
  }
}

class TaskEvidenceFailure implements Exception {
  const TaskEvidenceFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

bool _contentMatches(String extension, Uint8List bytes) {
  bool startsWith(List<int> signature) =>
      bytes.length >= signature.length &&
      List.generate(signature.length, (index) => bytes[index]).toString() ==
          signature.toString();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return startsWith(const [0xff, 0xd8, 0xff]);
    case 'png':
      return startsWith(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
    case 'webp':
      return bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP';
    case 'pdf':
      return String.fromCharCodes(bytes.take(4)) == '%PDF';
    case 'docx':
      return startsWith(const [0x50, 0x4b, 0x03, 0x04]);
    case 'txt':
      try {
        utf8.decode(bytes);
        return true;
      } on FormatException {
        return false;
      }
    default:
      return false;
  }
}
