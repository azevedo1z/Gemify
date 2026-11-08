import 'dart:convert';

import 'package:gemify/application/backup/backup_snapshot.dart';
import 'package:gemify/application/backup/expense_json.dart';
import 'package:gemify/application/change_log_entry.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/income_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_timeline.dart';
import 'package:gemify/domain/names.dart';
import 'package:gemify/domain/reference_month.dart';

enum BackupProblem {
  notGemifyBackup,
  unknownVersion,
  invalidStructure,
  invalidTimeline,
  invalidExpenses,
  invalidChangeLog,
}

sealed class BackupReading {
  const BackupReading();
}

final class BackupAccepted extends BackupReading {
  const BackupAccepted(this.snapshot);

  final BackupSnapshot snapshot;
}

final class BackupRejected extends BackupReading {
  const BackupRejected(this.problem);

  final BackupProblem problem;

  @override
  String toString() => 'BackupRejected($problem)';
}

abstract final class BackupCodec {
  static const format = 'gemify-backup';
  static const version = 1;
  static const _maxRecordId = 0x7FFFFFFF;
  static const _byteOrderMark = '\uFEFF';

  static String encode(
    BackupSnapshot snapshot, {
    required DateTime exportedAt,
  }) => const JsonEncoder.withIndent('  ').convert({
    'format': format,
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'months': [for (final month in snapshot.months) _encodeMonth(month)],
    'changeLog': [
      for (final entry in snapshot.changeLog) _encodeChange(entry),
    ],
  });

  static BackupReading decode(String text, {required CalendarDate today}) {
    try {
      final root = _Fields(jsonDecode(_withoutByteOrderMark(text)));
      if (root.optional<String>('format') != format) {
        return const BackupRejected(BackupProblem.notGemifyBackup);
      }
      if (root.optional<int>('version') != version) {
        return const BackupRejected(BackupProblem.unknownVersion);
      }
      final months = [
        for (final item in root.list('months')) _decodeMonth(item),
      ];
      final changeLog = [
        for (final item in root.list('changeLog')) _decodeChange(item),
      ];
      return _validate(
        BackupSnapshot(months: months, changeLog: changeLog),
        today,
      );
    } on FormatException {
      return const BackupRejected(BackupProblem.invalidStructure);
    }
  }

  static String _withoutByteOrderMark(String text) =>
      text.startsWith(_byteOrderMark) ? text.substring(1) : text;

  static BackupReading _validate(BackupSnapshot snapshot, CalendarDate today) {
    final months = snapshot.months;
    final entries = [for (final month in months) ...month.entries];
    if (!_validIds([for (final month in months) month.id]) ||
        !_validIds([for (final entry in entries) entry.id]) ||
        !_validIds([for (final entry in snapshot.changeLog) entry.id]) ||
        months.any((month) => !_incomeAccepted(month.income))) {
      return const BackupRejected(BackupProblem.invalidStructure);
    }
    if (MonthTimeline.errors(months).isNotEmpty) {
      return const BackupRejected(BackupProblem.invalidTimeline);
    }
    final invalidExpense = months.any(
      (month) => month.entries.any(
        (entry) =>
            !Names.isClean(entry.expense.name) ||
            ExpenseRules.errors(
              entry.expense,
              status: month.status,
              today: today,
            ).isNotEmpty,
      ),
    );
    if (invalidExpense) {
      return const BackupRejected(BackupProblem.invalidExpenses);
    }
    final monthIds = {for (final month in months) month.id};
    final orphanChange = snapshot.changeLog.any(
      (entry) => entry.monthId != null && !monthIds.contains(entry.monthId),
    );
    if (orphanChange) {
      return const BackupRejected(BackupProblem.invalidChangeLog);
    }
    return BackupAccepted(snapshot);
  }

  static bool _validIds(List<int> ids) =>
      ids.toSet().length == ids.length &&
      ids.every((id) => id >= 1 && id <= _maxRecordId);

  static bool _incomeAccepted(Money? income) =>
      income == null || IncomeRules.accepts(income);

  static Map<String, Object?> _encodeMonth(Month month) => {
    'id': month.id,
    'reference': month.reference.iso,
    'status': month.status.name,
    'incomeCents': month.income?.cents,
    'openedAt': month.openedAt.toUtc().toIso8601String(),
    'closedAt': month.closedAt?.toUtc().toIso8601String(),
    'expenses': [
      for (final entry in month.entries)
        {
          'id': entry.id,
          ...ExpenseJson.encode(entry.expense),
          'createdAt': entry.createdAt.toUtc().toIso8601String(),
          'updatedAt': entry.updatedAt.toUtc().toIso8601String(),
        },
    ],
  };

  static Map<String, Object?> _encodeChange(ChangeLogEntry entry) => {
    'id': entry.id,
    'occurredAt': entry.occurredAt.toUtc().toIso8601String(),
    'monthId': entry.monthId,
    'action': entry.action.name,
    'entityId': entry.entityId,
    'before': entry.before,
    'after': entry.after,
  };

  static Month _decodeMonth(Object? item) {
    final fields = _Fields(item);
    final status = _enumByName(MonthStatus.values, fields.required('status'));
    final incomeCents = fields.optional<int>('incomeCents');
    return Month(
      id: fields.required('id'),
      reference: ReferenceMonth.parse(fields.required('reference')),
      status: status,
      income: incomeCents == null ? null : Money(incomeCents),
      openedAt: _moment(fields.required('openedAt')),
      closedAt: switch (fields.optional<String>('closedAt')) {
        final text? => _moment(text),
        null => null,
      },
      entries: [
        for (final expense in fields.list('expenses')) _decodeEntry(expense),
      ],
    );
  }

  static ExpenseEntry _decodeEntry(Object? item) {
    final fields = _Fields(item);
    return ExpenseEntry(
      id: fields.required('id'),
      expense: _decodeExpense(fields),
      createdAt: _moment(fields.required('createdAt')),
      updatedAt: _moment(fields.required('updatedAt')),
    );
  }

  static Expense _decodeExpense(_Fields fields) {
    final name = fields.required<String>(ExpenseJson.name);
    final amount = Money(fields.required(ExpenseJson.amountCents));
    final current = fields.optional<int>(ExpenseJson.currentInstallment);
    final total = fields.optional<int>(ExpenseJson.totalInstallments);
    final spentOn = fields.optional<String>(ExpenseJson.spentOn);
    final category = _enumByName(
      ExpenseCategory.values,
      fields.required(ExpenseJson.category),
    );
    final hasCounters = current != null || total != null;
    switch (category) {
      case ExpenseCategory.fixed when !hasCounters && spentOn == null:
        return FixedExpense(name: name, amount: amount);
      case ExpenseCategory.installment
          when current != null && total != null && spentOn == null:
        return InstallmentExpense(
          name: name,
          amount: amount,
          current: current,
          total: total,
        );
      case ExpenseCategory.variable when !hasCounters:
        return VariableExpense(
          name: name,
          amount: amount,
          spentOn: spentOn == null ? null : CalendarDate.parse(spentOn),
        );
      case _:
        throw const FormatException('Fields do not match the category');
    }
  }

  static ChangeLogEntry _decodeChange(Object? item) {
    final fields = _Fields(item);
    return ChangeLogEntry(
      id: fields.required('id'),
      occurredAt: _moment(fields.required('occurredAt')),
      monthId: fields.optional('monthId'),
      action: _enumByName(ChangeAction.values, fields.required('action')),
      entityId: fields.optional('entityId'),
      before: fields.optional('before'),
      after: fields.optional('after'),
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, String name) =>
      values.where((value) => value.name == name).firstOrNull ??
      (throw FormatException('Unknown value', name));

  static DateTime _moment(String text) => DateTime.parse(text).toUtc();
}

final class _Fields {
  _Fields(Object? value)
    : _map = value is Map<String, Object?>
          ? value
          : throw const FormatException('Expected an object');

  final Map<String, Object?> _map;

  T required<T>(String key) => switch (_map[key]) {
    final T value => value,
    _ => throw FormatException('Missing or invalid field', key),
  };

  T? optional<T>(String key) => switch (_map[key]) {
    null => null,
    final T value => value,
    _ => throw FormatException('Invalid field', key),
  };

  List<Object?> list(String key) => required<List<Object?>>(key);
}
