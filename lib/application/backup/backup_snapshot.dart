import 'package:offmoney/application/change_log_entry.dart';
import 'package:offmoney/domain/month.dart';

final class BackupSnapshot {
  const BackupSnapshot({required this.months, required this.changeLog});

  final List<Month> months;
  final List<ChangeLogEntry> changeLog;
}
