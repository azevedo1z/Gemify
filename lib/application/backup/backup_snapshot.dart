import 'package:gemify/application/change_log_entry.dart';
import 'package:gemify/domain/month.dart';

final class BackupSnapshot {
  const BackupSnapshot({required this.months, required this.changeLog});

  final List<Month> months;
  final List<ChangeLogEntry> changeLog;
}
