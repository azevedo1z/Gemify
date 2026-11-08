import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/application/change_log_entry.dart';
import 'package:gemify/application/month_repository.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/builders.dart';
import '../support/memory_repository.dart';

ClosePlan planFor(
  Month month, {
  ReferenceMonth? to,
  Money? income,
}) => switch (MonthClosing.plan(
  month: month,
  newReference: to ?? month.reference.next(),
  newIncome: income,
  today: defaultToday,
)) {
  ClosePlanned(:final plan) => plan,
  final CloseRejected rejection => throw StateError('$rejection'),
};

void main() {
  late MemoryRepository memory;

  setUp(() async => memory = await MemoryRepository.open());
  tearDown(() => memory.close());

  group('first run', () {
    test('creates one open month, and running again changes nothing', () async {
      await memory.repository.ensureOpenMonth(ReferenceMonth(2030, 1));

      final snapshot = await memory.repository.snapshot();
      expect(snapshot.months, hasLength(1));
      expect(snapshot.months.single.reference, ReferenceMonth(2026, 11));
      expect(snapshot.months.single.isOpen, isTrue);
      expect(snapshot.months.single.income, isNull);
    });
  });

  group('without an open month', () {
    setUp(() => memory.database.delete(memory.database.months).go());

    test('reads and writes fail with a recoverable exception', () async {
      final repository = memory.repository;
      final noOpenMonth = throwsA(isA<NoOpenMonthException>());

      await expectLater(repository.openMonth(), noOpenMonth);
      await expectLater(repository.setIncome(Money.zero), noOpenMonth);
      await expectLater(
        repository.setOpenReference(ReferenceMonth(2026, 12)),
        noOpenMonth,
      );
      await expectLater(
        repository.addExpense(fixed('Condomínio', '750,00')),
        noOpenMonth,
      );
      await expectLater(
        repository.updateExpense(1, fixed('Condomínio', '750,00')),
        noOpenMonth,
      );
      await expectLater(repository.deleteExpense(1), noOpenMonth);
    });
  });

  group('writes on the open month', () {
    test('each change is stored and logged with old and new values', () async {
      final repository = memory.repository;

      await repository.setIncome(brl('4.800,00'));
      await repository.addExpense(fixed('Condomínio', '750,00'));
      final id = (await repository.openMonth()).entries.single.id;
      await repository.updateExpense(id, fixed('Condomínio', '800,00'));
      await repository.setOpenReference(ReferenceMonth(2026, 12));
      await repository.deleteExpense(id);

      final month = await repository.openMonth();
      expect(month.income, brl('4.800,00'));
      expect(month.reference, ReferenceMonth(2026, 12));
      expect(month.entries, isEmpty);

      final log = (await repository.snapshot()).changeLog;
      expect(
        [for (final entry in log) entry.action],
        [
          ChangeAction.incomeSet,
          ChangeAction.expenseCreated,
          ChangeAction.expenseUpdated,
          ChangeAction.referenceSet,
          ChangeAction.expenseDeleted,
        ],
      );
      expect(jsonDecode(log[0].before!), {'incomeCents': null});
      expect(jsonDecode(log[0].after!), {'incomeCents': 480000});
      expect(jsonDecode(log[2].before!), containsPair('amountCents', 75000));
      expect(jsonDecode(log[2].after!), containsPair('amountCents', 80000));
      expect(jsonDecode(log[3].after!), {'reference': '2026-12'});
      expect(log[4].entityId, id);
      expect(log[4].after, isNull);
    });

    test('stores every kind of item as it was given', () async {
      final expenses = <Expense>[
        fixed('Condomínio', '750,00'),
        installment('Monitor', '60,00', 7, 9),
        variable('Pão', '7,00', on: defaultToday),
      ];
      for (final expense in expenses) {
        await memory.repository.addExpense(expense);
      }

      final month = await memory.repository.openMonth();
      expect([for (final entry in month.entries) entry.expense], expenses);
      expect(
        month.entries.first.createdAt,
        DateTime.utc(2026, 11, 7, 12),
      );
    });

    test('an item never changes category', () async {
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));
      final id = (await memory.repository.openMonth()).entries.single.id;

      await expectLater(
        memory.repository.updateExpense(id, variable('Condomínio', '750,00')),
        throwsArgumentError,
      );
    });

    test('a failure after an item write leaves neither item nor log', () async {
      await memory.database.customStatement(
        'CREATE TRIGGER fail_log BEFORE INSERT ON change_log '
        "BEGIN SELECT RAISE(ABORT, 'forced'); END",
      );

      await expectLater(
        memory.repository.addExpense(fixed('Condomínio', '750,00')),
        throwsA(isA<SqliteException>()),
      );

      expect((await memory.repository.openMonth()).entries, isEmpty);
    });
  });

  group('close', () {
    Future<Month> monthWithItems() async {
      final repository = memory.repository;
      await repository.setIncome(brl('5.000,00'));
      await repository.addExpense(fixed('Condomínio', '750,00'));
      await repository.addExpense(installment('Monitor', '60,00', 8, 9));
      await repository.addExpense(installment('Fone de ouvido', '90,00', 2, 2));
      await repository.addExpense(variable('Pão', '7,00', on: defaultToday));
      return repository.openMonth();
    }

    test(
      'freezes the closed month and opens the next one from the plan',
      () async {
        final closing = await monthWithItems();

        await memory.repository.applyClose(
          planFor(closing, income: brl('4.800,00')),
        );

        final open = await memory.repository.openMonth();
        expect(open.reference, ReferenceMonth(2026, 12));
        expect(open.income, brl('4.800,00'));
        expect(
          [for (final entry in open.entries) entry.expense],
          [
            fixed('Condomínio', '750,00'),
            installment('Monitor', '60,00', 9, 9),
          ],
        );
        final closed = await memory.repository.watchMonth(closing.id).first;
        expect(closed.status, MonthStatus.closed);
        expect(closed.closedAt, DateTime.utc(2026, 11, 7, 12));
        expect(closed.entries, closing.entries);
        final log = (await memory.repository.snapshot()).changeLog.last;
        expect(log.action, ChangeAction.monthClosed);
        expect(jsonDecode(log.after!), containsPair('installmentsFinished', 1));
      },
    );

    test('the same plan applied twice fails and writes nothing', () async {
      final plan = planFor(await monthWithItems());
      await memory.repository.applyClose(plan);
      final before = await memory.repository.snapshot();

      await expectLater(
        memory.repository.applyClose(plan),
        throwsA(isA<CloseConflictException>()),
      );

      final after = await memory.repository.snapshot();
      expect(after.months.length, before.months.length);
      expect(after.changeLog.length, before.changeLog.length);
      expect(
        (await memory.repository.openMonth()).reference,
        plan.newReference,
      );
    });

    test('a second plan of a month already closed is a conflict', () async {
      final closing = await monthWithItems();
      final toDecember = planFor(closing);
      final toJanuary = planFor(closing, to: ReferenceMonth(2027, 1));
      await memory.repository.applyClose(toDecember);
      final before = await memory.repository.snapshot();

      await expectLater(
        memory.repository.applyClose(toJanuary),
        throwsA(isA<CloseConflictException>()),
      );

      final after = await memory.repository.snapshot();
      expect(after.months.length, before.months.length);
      expect(after.changeLog.length, before.changeLog.length);
      expect(
        (await memory.repository.openMonth()).reference,
        ReferenceMonth(2026, 12),
      );
    });

    test('a failure in the middle rolls everything back', () async {
      final closing = await monthWithItems();
      await memory.database.customStatement(
        'CREATE TRIGGER fail_new_items BEFORE INSERT ON expenses '
        "BEGIN SELECT RAISE(ABORT, 'forced'); END",
      );

      await expectLater(
        memory.repository.applyClose(planFor(closing)),
        throwsA(isA<SqliteException>()),
      );

      final open = await memory.repository.openMonth();
      expect(open.id, closing.id);
      expect(open.entries, closing.entries);
    });

    test('items of a closed month can no longer be changed', () async {
      final closing = await monthWithItems();
      await memory.repository.applyClose(planFor(closing));
      final oldId = closing.entries.first.id;

      await expectLater(
        memory.repository.updateExpense(oldId, fixed('Condomínio', '1,00')),
        throwsA(isA<ExpenseNotInOpenMonthException>()),
      );
      await expectLater(
        memory.repository.deleteExpense(oldId),
        throwsA(isA<ExpenseNotInOpenMonthException>()),
      );
    });

    test(
      'history lists closed months, newest first, with exact sums',
      () async {
        await memory.repository.applyClose(planFor(await monthWithItems()));
        await memory.repository.addExpense(
          variable('Mercado', '600,00', on: defaultToday),
        );
        await memory.repository.applyClose(
          planFor(await memory.repository.openMonth()),
        );

        final history = await memory.repository.watchClosedMonths().first;

        expect(
          [for (final month in history) month.reference],
          [
            ReferenceMonth(2026, 12),
            ReferenceMonth(2026, 11),
          ],
        );
        expect(history.first.summary.fixedTotal, brl('750,00'));
        expect(history.first.summary.installmentTotal, brl('60,00'));
        expect(history.first.summary.variableTotal, brl('600,00'));
        expect(history.first.summary.balance, brl('3.590,00'));
        expect(history.last.summary.balance, brl('4.093,00'));
        expect(
          await memory.repository.latestClosedReference(),
          ReferenceMonth(2026, 12),
        );
      },
    );
  });

  group('backup', () {
    test(
      'a snapshot restores into the same data plus the import entry',
      () async {
        await memory.repository.setIncome(brl('4.800,00'));
        await memory.repository.addExpense(installment('TV', '120,00', 8, 18));
        await memory.repository.applyClose(
          planFor(await memory.repository.openMonth()),
        );
        await memory.repository.addExpense(
          variable('Pão', '7,00', on: defaultToday),
        );
        memory.clock.advance();
        final bread = (await memory.repository.openMonth()).entries.firstWhere(
          (entry) => entry.expense.name == 'Pão',
        );
        await memory.repository.updateExpense(
          bread.id,
          variable('Pão', '8,00', on: defaultToday),
        );
        final original = await memory.repository.snapshot();
        final copy = await MemoryRepository.open(
          firstMonth: ReferenceMonth(2000, 1),
        );
        addTearDown(copy.close);

        await copy.repository.replaceAll(original);

        final restored = await copy.repository.snapshot();
        expect(
          [for (final month in restored.months) month.entries],
          [for (final month in original.months) month.entries],
        );
        expect(
          [for (final month in restored.months) month.reference],
          [for (final month in original.months) month.reference],
        );
        expect(
          [for (final entry in restored.changeLog) entry.id],
          [
            for (final entry in original.changeLog) entry.id,
            original.changeLog.length + 1,
          ],
        );
        expect(restored.changeLog.last.action, ChangeAction.backupImported);
      },
    );

    test('replacing removes every previous month, item and log', () async {
      final source = await MemoryRepository.open(
        firstMonth: ReferenceMonth(2030, 1),
      );
      addTearDown(source.close);
      await memory.repository.setIncome(brl('1.000,00'));
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));

      await memory.repository.replaceAll(await source.repository.snapshot());

      final replaced = await memory.repository.snapshot();
      expect(
        [for (final month in replaced.months) month.reference],
        [ReferenceMonth(2030, 1)],
      );
      expect(replaced.months.single.entries, isEmpty);
      expect(
        [for (final entry in replaced.changeLog) entry.action],
        [ChangeAction.backupImported],
      );
    });

    test('a failed replace keeps the previous data', () async {
      await memory.repository.setIncome(brl('1.000,00'));
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));
      final before = await memory.repository.snapshot();
      final source = await MemoryRepository.open(
        firstMonth: ReferenceMonth(2030, 1),
      );
      addTearDown(source.close);
      final replacement = await source.repository.snapshot();
      await memory.database.customStatement(
        'CREATE TRIGGER fail_log BEFORE INSERT ON change_log '
        "BEGIN SELECT RAISE(ABORT, 'forced'); END",
      );

      await expectLater(
        memory.repository.replaceAll(replacement),
        throwsA(isA<SqliteException>()),
      );

      final after = await memory.repository.snapshot();
      expect(
        [for (final month in after.months) month.entries],
        [for (final month in before.months) month.entries],
      );
      expect(after.months.single.income, brl('1.000,00'));
      expect(after.changeLog.length, before.changeLog.length);
    });
  });

  group('names', () {
    test('used names come from the category, most recent first', () async {
      await memory.repository.addExpense(
        variable('Uber', '20,00', on: defaultToday),
      );
      memory.clock.advance();
      await memory.repository.addExpense(
        variable('Pão', '7,00', on: defaultToday),
      );
      memory.clock.advance();
      await memory.repository.addExpense(
        variable('Uber', '15,00', on: defaultToday),
      );
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));

      expect(
        await memory.repository.usedNames(ExpenseCategory.variable),
        ['Uber', 'Pão'],
      );
    });
  });

  group('database constraints', () {
    const at = "'2026-11-07T12:00:00.000Z'";
    final aboveCap = Money.max.cents + 1;
    const belowMinimum = ExpenseRules.minimumInstallments - 1;
    const pastLastMonth = ReferenceMonth.monthsInYear + 1;
    final invalidStatements = {
      'amount zero':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "created_at, updated_at) VALUES (1, 'fixed', 'X', 0, $at, $at)",
      'amount above the cap':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "created_at, updated_at) VALUES (1, 'fixed', 'X', $aboveCap, "
          '$at, $at)',
      'unknown category':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "created_at, updated_at) VALUES (1, 'other', 'X', 1, $at, $at)",
      'installment without counters':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "created_at, updated_at) VALUES (1, 'installment', 'X', 1, $at, $at)",
      'installment total below the minimum':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          'current_installment, total_installments, created_at, updated_at) '
          "VALUES (1, 'installment', 'X', 1, 1, $belowMinimum, $at, $at)",
      'installment current above total':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          'current_installment, total_installments, created_at, updated_at) '
          "VALUES (1, 'installment', 'X', 1, 4, 3, $at, $at)",
      'counters on a fixed item':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          'current_installment, total_installments, created_at, updated_at) '
          "VALUES (1, 'fixed', 'X', 1, 1, 2, $at, $at)",
      'date on a fixed item':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "spent_on, created_at, updated_at) VALUES (1, 'fixed', 'X', 1, "
          "'2026-11-07', $at, $at)",
      'expense of a missing month':
          'INSERT INTO expenses (month_id, category, name, amount_cents, '
          "created_at, updated_at) VALUES (99, 'fixed', 'X', 1, $at, $at)",
      'second open month':
          'INSERT INTO months (reference_year, reference_month, status, '
          "opened_at) VALUES (2026, 12, 'open', $at)",
      'repeated reference':
          'INSERT INTO months (reference_year, reference_month, status, '
          "income_cents, opened_at, closed_at) VALUES (2026, 11, 'closed', 1, "
          '$at, $at)',
      'reference month past the last one':
          'INSERT INTO months (reference_year, reference_month, status, '
          'income_cents, opened_at, closed_at) '
          "VALUES (2026, $pastLastMonth, 'closed', 1, $at, $at)",
      'unknown status':
          'INSERT INTO months (reference_year, reference_month, status, '
          "opened_at) VALUES (2026, 10, 'paused', $at)",
      'closed month without close time':
          'INSERT INTO months (reference_year, reference_month, status, '
          "income_cents, opened_at) VALUES (2026, 10, 'closed', 1, $at)",
      'negative income':
          'INSERT INTO months (reference_year, reference_month, status, '
          "income_cents, opened_at, closed_at) VALUES (2026, 10, 'closed', -1, "
          '$at, $at)',
      'income above the cap':
          'INSERT INTO months (reference_year, reference_month, status, '
          'income_cents, opened_at, closed_at) '
          "VALUES (2026, 10, 'closed', $aboveCap, $at, $at)",
      'closed month without income':
          'INSERT INTO months (reference_year, reference_month, status, '
          "opened_at, closed_at) VALUES (2026, 10, 'closed', $at, $at)",
      'log of a missing month':
          'INSERT INTO change_log (occurred_at, month_id, action) '
          "VALUES ($at, 99, 'incomeSet')",
    };

    for (final MapEntry(key: description, value: statement)
        in invalidStatements.entries) {
      test('rejects $description', () async {
        await expectLater(
          memory.database.customStatement(statement),
          throwsA(isA<SqliteException>()),
        );
      });
    }

    test('accepts amounts and income exactly at the cap', () async {
      await memory.repository.setIncome(Money.max);
      await memory.repository.addExpense(
        const FixedExpense(name: 'Teto', amount: Money.max),
      );

      final month = await memory.repository.openMonth();
      expect(month.income, Money.max);
      expect(month.entries.single.expense.amount, Money.max);
    });

    test('accepts installments at the minimum and the last month', () async {
      await memory.repository.addExpense(
        installment(
          'Fone de ouvido',
          '90,00',
          ExpenseRules.minimumInstallments,
          ExpenseRules.minimumInstallments,
        ),
      );
      await memory.repository.setOpenReference(
        ReferenceMonth(2026, ReferenceMonth.monthsInYear),
      );

      final month = await memory.repository.openMonth();
      expect(month.entries, hasLength(1));
      expect(month.reference.month, ReferenceMonth.monthsInYear);
    });
  });
}
