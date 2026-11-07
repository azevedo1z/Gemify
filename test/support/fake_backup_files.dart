import 'package:gemify/presentation/backup/backup_files.dart';

final class FakeBackupFiles implements BackupFiles {
  final List<String> saved = [];
  bool cancelSave = false;
  Exception? saveFailure;
  String? fileToOpen;
  Exception? openFailure;

  @override
  Future<bool> save(String fileName, String content) async {
    if (saveFailure case final failure?) throw failure;
    if (cancelSave) return false;
    saved.add(content);
    return true;
  }

  @override
  Future<String?> open() async {
    if (openFailure case final failure?) throw failure;
    return fileToOpen;
  }
}
