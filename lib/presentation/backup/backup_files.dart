import 'dart:convert';

import 'package:file_picker/file_picker.dart';

abstract interface class BackupFiles {
  Future<bool> save(String fileName, String content);

  Future<String?> open();
}

final class PickerBackupFiles implements BackupFiles {
  const PickerBackupFiles();

  static const _jsonMimeType = 'application/json';
  static const int _maxBytes = 20 * 1024 * 1024;

  @override
  Future<bool> save(String fileName, String content) async =>
      await FilePicker.saveFile(
        fileName: fileName,
        bytes: utf8.encode(content),
        mimeType: _jsonMimeType,
      ) !=
      null;

  @override
  Future<String?> open() async {
    final files = await FilePicker.pickFiles();
    if (files.isEmpty) return null;
    final file = files.first;
    final length = await file.length();
    if (length == null || length > _maxBytes) {
      throw const FormatException('The file is unreadable or too large');
    }
    return utf8.decode(await file.readAsBytes());
  }
}
