import 'package:offmoney/application/backup/backup_snapshot.dart';
import 'package:offmoney/application/change_log_entry.dart';
import 'package:offmoney/domain/month.dart';

List<Object?> describeMonths(BackupSnapshot snapshot) => [
  for (final Month month in snapshot.months)
    [
      month.id,
      month.reference,
      month.status,
      month.income,
      month.openedAt,
      month.closedAt,
      month.entries,
    ],
];

List<Object?> describeChanges(Iterable<ChangeLogEntry> changeLog) => [
  for (final entry in changeLog)
    [
      entry.id,
      entry.occurredAt,
      entry.monthId,
      entry.action,
      entry.entityId,
      entry.before,
      entry.after,
    ],
];
