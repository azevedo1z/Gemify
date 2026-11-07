enum ChangeAction {
  incomeSet,
  referenceSet,
  expenseCreated,
  expenseUpdated,
  expenseDeleted,
  monthClosed,
  backupImported,
}

final class ChangeLogEntry {
  const ChangeLogEntry({
    required this.id,
    required this.occurredAt,
    required this.monthId,
    required this.action,
    required this.entityId,
    required this.before,
    required this.after,
  });

  final int id;
  final DateTime occurredAt;
  final int? monthId;
  final ChangeAction action;
  final int? entityId;
  final String? before;
  final String? after;
}
