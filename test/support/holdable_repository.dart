import 'dart:async';

import 'package:offmoney/application/backup/backup_snapshot.dart';
import 'package:offmoney/application/month_repository.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_closing.dart';
import 'package:offmoney/domain/reference_month.dart';

final class HoldableRepository implements MonthRepository {
  HoldableRepository(this._inner);

  final MonthRepository _inner;
  Completer<void>? _hold;

  void holdWrites() => _hold = Completer<void>();

  void releaseWrites() {
    _hold?.complete();
    _hold = null;
  }

  Future<T> _write<T>(Future<T> Function() write) async {
    await _hold?.future;
    return write();
  }

  @override
  Stream<Month> watchOpenMonth() => _inner.watchOpenMonth();

  @override
  Stream<Month> watchMonth(int id) => _inner.watchMonth(id);

  @override
  Stream<List<MonthOverview>> watchClosedMonths() => _inner.watchClosedMonths();

  @override
  Future<Month> openMonth() => _inner.openMonth();

  @override
  Future<ReferenceMonth?> latestClosedReference() =>
      _inner.latestClosedReference();

  @override
  Future<List<String>> usedNames(ExpenseCategory category) =>
      _inner.usedNames(category);

  @override
  Future<BackupSnapshot> snapshot() => _inner.snapshot();

  @override
  Future<void> ensureOpenMonth(ReferenceMonth reference) =>
      _write(() => _inner.ensureOpenMonth(reference));

  @override
  Future<void> setIncome(Money income) =>
      _write(() => _inner.setIncome(income));

  @override
  Future<void> setOpenReference(ReferenceMonth reference) =>
      _write(() => _inner.setOpenReference(reference));

  @override
  Future<void> addExpense(Expense expense) =>
      _write(() => _inner.addExpense(expense));

  @override
  Future<void> updateExpense(int id, Expense expense) =>
      _write(() => _inner.updateExpense(id, expense));

  @override
  Future<void> deleteExpense(int id) => _write(() => _inner.deleteExpense(id));

  @override
  Future<void> applyClose(ClosePlan plan) =>
      _write(() => _inner.applyClose(plan));

  @override
  Future<void> replaceAll(BackupSnapshot snapshot) =>
      _write(() => _inner.replaceAll(snapshot));
}
