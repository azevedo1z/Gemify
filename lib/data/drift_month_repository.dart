import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:gemify/application/backup/backup_snapshot.dart';
import 'package:gemify/application/backup/expense_json.dart';
import 'package:gemify/application/change_log_entry.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_repository.dart';
import 'package:gemify/data/gemify_database.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/month_summary.dart';
import 'package:gemify/domain/reference_month.dart';

typedef _MonthGroup = ({MonthRow month, List<ExpenseEntry> entries});

final class DriftMonthRepository implements MonthRepository {
  DriftMonthRepository(this._db, {required Clock clock}) : _clock = clock;

  final GemifyDatabase _db;
  final Clock _clock;

  static final String _open = MonthStatus.open.name;
  static final String _closed = MonthStatus.closed.name;

  @override
  Stream<Month> watchOpenMonth() => _monthsWhere(
    _db.months.status.equals(_open),
  ).watch().map((rows) => _monthsOf(rows).single);

  @override
  Stream<Month> watchMonth(int id) => _monthsWhere(
    _db.months.id.equals(id),
  ).watch().map((rows) => _monthsOf(rows).single);

  @override
  Stream<List<MonthOverview>> watchClosedMonths() {
    final amount = _db.expenses.amountCents;
    final category = _db.expenses.category;
    final sums = {
      for (final value in ExpenseCategory.values)
        value: amount.sum(filter: category.equals(value.name)),
    };
    final query =
        _db.select(_db.months).join([
            leftOuterJoin(
              _db.expenses,
              _db.expenses.monthId.equalsExp(_db.months.id),
              useColumns: false,
            ),
          ])
          ..addColumns(sums.values)
          ..where(_db.months.status.equals(_closed))
          ..groupBy([_db.months.id])
          ..orderBy([
            OrderingTerm.desc(_db.months.referenceYear),
            OrderingTerm.desc(_db.months.referenceMonth),
          ]);
    Money sumOf(TypedResult row, ExpenseCategory category) =>
        Money(row.read(sums[category]!) ?? 0);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _overviewOf(
            row.readTable(_db.months),
            MonthSummary(
              income: _incomeOf(row.readTable(_db.months)),
              fixedTotal: sumOf(row, ExpenseCategory.fixed),
              installmentTotal: sumOf(row, ExpenseCategory.installment),
              variableTotal: sumOf(row, ExpenseCategory.variable),
            ),
          ),
      ],
    );
  }

  @override
  Future<Month> openMonth() async => _monthsOf(
    await _monthsWhere(_db.months.status.equals(_open)).get(),
  ).single;

  @override
  Future<ReferenceMonth?> latestClosedReference() async {
    final row =
        await (_db.select(_db.months)
              ..where((month) => month.status.equals(_closed))
              ..orderBy([
                (month) => OrderingTerm.desc(month.referenceYear),
                (month) => OrderingTerm.desc(month.referenceMonth),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _referenceOf(row);
  }

  @override
  Future<List<String>> usedNames(ExpenseCategory category) async {
    final name = _db.expenses.name;
    final latestUse = _db.expenses.createdAt.max();
    final rows =
        await (_db.selectOnly(_db.expenses)
              ..addColumns([name, latestUse])
              ..where(_db.expenses.category.equals(category.name))
              ..groupBy([name])
              ..orderBy([OrderingTerm.desc(latestUse)]))
            .get();
    return [for (final row in rows) ?row.read(name)];
  }

  @override
  Future<void> ensureOpenMonth(ReferenceMonth reference) =>
      _db.transaction(() async {
        final existing = await (_db.select(
          _db.months,
        )..where((month) => month.status.equals(_open))).getSingleOrNull();
        if (existing != null) return;
        await _db
            .into(_db.months)
            .insert(
              MonthsCompanion.insert(
                referenceYear: reference.year,
                referenceMonth: reference.month,
                status: _open,
                openedAt: _clock(),
              ),
            );
      });

  @override
  Future<void> setIncome(Money income) => _db.transaction(() async {
    final month = await _openMonthRow();
    _expectOne(
      await _updateOpenMonth(
        month.id,
        MonthsCompanion(incomeCents: Value(income.cents)),
      ),
    );
    await _log(
      ChangeAction.incomeSet,
      monthId: month.id,
      entityId: month.id,
      before: _incomeJson(month.incomeCents),
      after: _incomeJson(income.cents),
    );
  });

  @override
  Future<void> setOpenReference(ReferenceMonth reference) =>
      _db.transaction(() async {
        final month = await _openMonthRow();
        _expectOne(
          await _updateOpenMonth(
            month.id,
            MonthsCompanion(
              referenceYear: Value(reference.year),
              referenceMonth: Value(reference.month),
            ),
          ),
        );
        await _log(
          ChangeAction.referenceSet,
          monthId: month.id,
          entityId: month.id,
          before: _referenceJson(_referenceOf(month)),
          after: _referenceJson(reference),
        );
      });

  @override
  Future<void> addExpense(Expense expense) => _db.transaction(() async {
    final month = await _openMonthRow();
    final id = await _db
        .into(_db.expenses)
        .insert(_insertOf(expense, month.id, _clock()));
    await _log(
      ChangeAction.expenseCreated,
      monthId: month.id,
      entityId: id,
      after: _expenseJson(expense),
    );
  });

  @override
  Future<void> updateExpense(int id, Expense expense) =>
      _db.transaction(() async {
        final month = await _openMonthRow();
        final row = await _openExpenseRow(id, month.id);
        if (row.category != expense.category.name) {
          throw ArgumentError('The category of an expense never changes');
        }
        _expectOne(
          await (_db.update(_db.expenses)..where(
                (item) => item.id.equals(id) & item.monthId.equals(month.id),
              ))
              .write(_updateOf(expense, _clock())),
        );
        await _log(
          ChangeAction.expenseUpdated,
          monthId: month.id,
          entityId: id,
          before: _expenseJson(_expenseOf(row)),
          after: _expenseJson(expense),
        );
      });

  @override
  Future<void> deleteExpense(int id) => _db.transaction(() async {
    final month = await _openMonthRow();
    final row = await _openExpenseRow(id, month.id);
    _expectOne(
      await (_db.delete(_db.expenses)..where(
            (item) => item.id.equals(id) & item.monthId.equals(month.id),
          ))
          .go(),
    );
    await _log(
      ChangeAction.expenseDeleted,
      monthId: month.id,
      entityId: id,
      before: _expenseJson(_expenseOf(row)),
    );
  });

  @override
  Future<void> applyClose(ClosePlan plan) => _db.transaction(() async {
    final now = _clock();
    final closed = await _updateOpenMonth(
      plan.closingMonthId,
      MonthsCompanion(status: Value(_closed), closedAt: Value(now)),
    );
    if (closed != 1) throw CloseConflictException(plan.closingMonthId);
    final newMonthId = await _db
        .into(_db.months)
        .insert(
          MonthsCompanion.insert(
            referenceYear: plan.newReference.year,
            referenceMonth: plan.newReference.month,
            status: _open,
            incomeCents: Value(plan.newIncome.cents),
            openedAt: now,
          ),
        );
    await _db.batch(
      (batch) => batch.insertAll(_db.expenses, [
        for (final expense in plan.newExpenses)
          _insertOf(expense, newMonthId, now),
      ]),
    );
    await _log(
      ChangeAction.monthClosed,
      monthId: plan.closingMonthId,
      entityId: newMonthId,
      after: jsonEncode({
        'closedReference': plan.closingReference.iso,
        'newReference': plan.newReference.iso,
        'newIncomeCents': plan.newIncome.cents,
        'incomeKept': plan.incomeKept,
        'fixedKept': plan.keptFixed.length,
        'installmentsAdvanced': plan.advancing.length,
        'installmentsFinished': plan.finishing.length,
        'variablesCleared': plan.clearedVariables.length,
      }),
    );
  });

  @override
  Future<BackupSnapshot> snapshot() => _db.transaction(() async {
    final months = _monthsOf(await _monthsWhere(const Constant(true)).get());
    final log = await (_db.select(
      _db.changeLog,
    )..orderBy([(entry) => OrderingTerm.asc(entry.id)])).get();
    return BackupSnapshot(
      months: months,
      changeLog: [for (final row in log) _changeLogEntryOf(row)],
    );
  });

  @override
  Future<void> replaceAll(BackupSnapshot snapshot) => _db.transaction(() async {
    await _db.delete(_db.changeLog).go();
    await _db.delete(_db.expenses).go();
    await _db.delete(_db.months).go();
    await _db.batch((batch) {
      batch
        ..insertAll(_db.months, [
          for (final month in snapshot.months) _monthInsertOf(month),
        ])
        ..insertAll(_db.expenses, [
          for (final month in snapshot.months)
            for (final entry in month.entries)
              _insertOf(entry.expense, month.id, entry.createdAt).copyWith(
                id: Value(entry.id),
                updatedAt: Value(entry.updatedAt),
              ),
        ])
        ..insertAll(_db.changeLog, [
          for (final entry in snapshot.changeLog) _changeLogInsertOf(entry),
        ]);
    });
    await _log(
      ChangeAction.backupImported,
      monthId: null,
      entityId: null,
      after: jsonEncode({
        'months': snapshot.months.length,
        'changeLogEntries': snapshot.changeLog.length,
      }),
    );
  });

  JoinedSelectStatement<HasResultSet, dynamic> _monthsWhere(
    Expression<bool> filter,
  ) =>
      _db.select(_db.months).join([
          leftOuterJoin(
            _db.expenses,
            _db.expenses.monthId.equalsExp(_db.months.id),
          ),
        ])
        ..where(filter)
        ..orderBy([OrderingTerm.asc(_db.expenses.id)]);

  List<Month> _monthsOf(List<TypedResult> rows) {
    final groups = <int, _MonthGroup>{};
    for (final row in rows) {
      final month = row.readTable(_db.months);
      final group = groups.putIfAbsent(
        month.id,
        () => (month: month, entries: <ExpenseEntry>[]),
      );
      if (row.readTableOrNull(_db.expenses) case final expense?) {
        group.entries.add(
          ExpenseEntry(
            id: expense.id,
            expense: _expenseOf(expense),
            createdAt: expense.createdAt,
            updatedAt: expense.updatedAt,
          ),
        );
      }
    }
    return [
      for (final group in groups.values) _monthOf(group.month, group.entries),
    ];
  }

  Month _monthOf(MonthRow row, List<ExpenseEntry> entries) => Month(
    id: row.id,
    reference: _referenceOf(row),
    status: MonthStatus.values.byName(row.status),
    income: _incomeOf(row),
    openedAt: row.openedAt,
    closedAt: row.closedAt,
    entries: entries,
  );

  MonthOverview _overviewOf(MonthRow row, MonthSummary summary) =>
      MonthOverview(id: row.id, reference: _referenceOf(row), summary: summary);

  ReferenceMonth _referenceOf(MonthRow row) =>
      ReferenceMonth(row.referenceYear, row.referenceMonth);

  Money? _incomeOf(MonthRow row) {
    final cents = row.incomeCents;
    return cents == null ? null : Money(cents);
  }

  Expense _expenseOf(ExpenseRow row) {
    final amount = Money(row.amountCents);
    return switch (ExpenseCategory.values.byName(row.category)) {
      ExpenseCategory.fixed => FixedExpense(name: row.name, amount: amount),
      ExpenseCategory.installment => InstallmentExpense(
        name: row.name,
        amount: amount,
        current: _stored(row.currentInstallment, 'current_installment'),
        total: _stored(row.totalInstallments, 'total_installments'),
      ),
      ExpenseCategory.variable => VariableExpense(
        name: row.name,
        amount: amount,
        spentOn: switch (row.spentOn) {
          final iso? => CalendarDate.parse(iso),
          null => null,
        },
      ),
    };
  }

  ExpensesCompanion _insertOf(Expense expense, int monthId, DateTime now) {
    final details = _detailsOf(expense);
    return ExpensesCompanion.insert(
      monthId: monthId,
      category: expense.category.name,
      name: expense.name,
      amountCents: expense.amount.cents,
      currentInstallment: Value(details.current),
      totalInstallments: Value(details.total),
      spentOn: Value(details.spentOn),
      createdAt: now,
      updatedAt: now,
    );
  }

  ExpensesCompanion _updateOf(Expense expense, DateTime now) {
    final details = _detailsOf(expense);
    return ExpensesCompanion(
      name: Value(expense.name),
      amountCents: Value(expense.amount.cents),
      currentInstallment: Value(details.current),
      totalInstallments: Value(details.total),
      spentOn: Value(details.spentOn),
      updatedAt: Value(now),
    );
  }

  ({int? current, int? total, String? spentOn}) _detailsOf(Expense expense) =>
      switch (expense) {
        FixedExpense() => (current: null, total: null, spentOn: null),
        InstallmentExpense(:final current, :final total) => (
          current: current,
          total: total,
          spentOn: null,
        ),
        VariableExpense(:final spentOn) => (
          current: null,
          total: null,
          spentOn: spentOn?.iso,
        ),
      };

  MonthsCompanion _monthInsertOf(Month month) => MonthsCompanion.insert(
    id: Value(month.id),
    referenceYear: month.reference.year,
    referenceMonth: month.reference.month,
    status: month.status.name,
    incomeCents: Value(month.income?.cents),
    openedAt: month.openedAt,
    closedAt: Value(month.closedAt),
  );

  ChangeLogEntry _changeLogEntryOf(ChangeLogRow row) => ChangeLogEntry(
    id: row.id,
    occurredAt: row.occurredAt,
    monthId: row.monthId,
    action: ChangeAction.values.byName(row.action),
    entityId: row.entityId,
    before: row.beforeJson,
    after: row.afterJson,
  );

  ChangeLogCompanion _changeLogInsertOf(ChangeLogEntry entry) =>
      ChangeLogCompanion.insert(
        id: Value(entry.id),
        occurredAt: entry.occurredAt,
        monthId: Value(entry.monthId),
        action: entry.action.name,
        entityId: Value(entry.entityId),
        beforeJson: Value(entry.before),
        afterJson: Value(entry.after),
      );

  Future<MonthRow> _openMonthRow() async {
    final row = await (_db.select(
      _db.months,
    )..where((month) => month.status.equals(_open))).getSingleOrNull();
    return row ?? (throw StateError('There is no open month'));
  }

  Future<ExpenseRow> _openExpenseRow(int id, int openMonthId) async {
    final row =
        await (_db.select(_db.expenses)..where(
              (item) => item.id.equals(id) & item.monthId.equals(openMonthId),
            ))
            .getSingleOrNull();
    return row ?? (throw StateError('Expense $id is not in the open month'));
  }

  Future<int> _updateOpenMonth(int id, MonthsCompanion changes) =>
      (_db.update(_db.months)..where(
            (month) => month.id.equals(id) & month.status.equals(_open),
          ))
          .write(changes);

  Future<void> _log(
    ChangeAction action, {
    required int? monthId,
    required int? entityId,
    String? before,
    String? after,
  }) => _db
      .into(_db.changeLog)
      .insert(
        ChangeLogCompanion.insert(
          occurredAt: _clock(),
          monthId: Value(monthId),
          action: action.name,
          entityId: Value(entityId),
          beforeJson: Value(before),
          afterJson: Value(after),
        ),
      );

  static void _expectOne(int affectedRows) {
    if (affectedRows != 1) {
      throw StateError('Expected one row to change, got $affectedRows');
    }
  }

  static int _stored(int? value, String column) =>
      value ?? (throw StateError('Column $column is missing'));

  static String _expenseJson(Expense expense) =>
      jsonEncode(ExpenseJson.encode(expense));

  static String _incomeJson(int? cents) => jsonEncode({'incomeCents': cents});

  static String _referenceJson(ReferenceMonth reference) =>
      jsonEncode({'reference': reference.iso});
}
