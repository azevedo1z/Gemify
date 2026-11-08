import 'package:gemify/application/backup/backup_snapshot.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/month_summary.dart';
import 'package:gemify/domain/reference_month.dart';

final class MonthOverview {
  const MonthOverview({
    required this.id,
    required this.reference,
    required this.summary,
  });

  final int id;
  final ReferenceMonth reference;
  final MonthSummary summary;
}

final class CloseConflictException implements Exception {
  const CloseConflictException(this.closingMonthId);

  final int closingMonthId;

  @override
  String toString() => 'Month $closingMonthId is no longer open';
}

final class NoOpenMonthException implements Exception {
  const NoOpenMonthException();

  @override
  String toString() => 'There is no open month';
}

final class ExpenseNotInOpenMonthException implements Exception {
  const ExpenseNotInOpenMonthException(this.expenseId);

  final int expenseId;

  @override
  String toString() => 'Expense $expenseId is not in the open month';
}

abstract interface class MonthRepository {
  Stream<Month> watchOpenMonth();

  Stream<Month> watchMonth(int id);

  Stream<List<MonthOverview>> watchClosedMonths();

  Future<Month> openMonth();

  Future<ReferenceMonth?> latestClosedReference();

  Future<List<String>> usedNames(ExpenseCategory category);

  Future<void> ensureOpenMonth(ReferenceMonth reference);

  Future<void> setIncome(Money income);

  Future<void> setOpenReference(ReferenceMonth reference);

  Future<void> addExpense(Expense expense);

  Future<void> updateExpense(int id, Expense expense);

  Future<void> deleteExpense(int id);

  Future<void> applyClose(ClosePlan plan);

  Future<BackupSnapshot> snapshot();

  Future<void> replaceAll(BackupSnapshot snapshot);
}
