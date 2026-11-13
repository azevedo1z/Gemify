import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/application/change_log_entry.dart';
import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_closing.dart';
import 'package:offmoney/domain/reference_month.dart';

import '../support/builders.dart';
import '../support/memory_repository.dart';
import '../support/sample_cycle.dart';

final class CycleScenario {
  CycleScenario(this.memory);

  final MemoryRepository memory;

  late final save = SaveExpense(memory.repository, memory.clock.call);
  late final setIncome = SetIncome(memory.repository);
  late final prepareClose = PrepareClose(memory.clock.call);
  late final confirmClose = ConfirmClose(memory.repository);
  late final delete = DeleteExpense(memory.repository);

  Future<Month> openMonth() => memory.repository.openMonth();

  Future<ClosePlan> plan({Money? newIncome}) async =>
      planOf(prepareClose(await openMonth(), newIncome: newIncome));

  Future<void> closeTheFirstMonth() async {
    await setIncome(brl('5.000,00'));
    for (final expense in [
      ...sampleFixedExpenses,
      ...sampleInstallmentsBeforeClose,
      variable('Mercado de outubro', '320,00', on: defaultToday),
    ]) {
      await save(expense);
    }
    await confirmClose(await plan(newIncome: brl('4.800,00')));
  }

  Future<void> addTheVariables() async {
    for (final batch in sampleVariableBatches) {
      for (final expense in batch) {
        await save(expense);
      }
    }
  }
}

List<Expense> expensesOf(Month month, ExpenseCategory category) => [
  for (final ExpenseEntry(:expense) in month.entries)
    if (expense.category == category) expense,
];

void main() {
  late MemoryRepository memory;
  late CycleScenario cycle;

  setUp(() async {
    memory = await MemoryRepository.open(firstMonth: ReferenceMonth(2026, 10));
    cycle = CycleScenario(memory);
  });
  tearDown(() => memory.close());

  test('AT1: a month close', () async {
    await cycle.closeTheFirstMonth();

    final month = await cycle.openMonth();
    expect(month.reference, ReferenceMonth(2026, 11));
    expect(expensesOf(month, ExpenseCategory.fixed), sampleFixedExpenses);
    expect(
      expensesOf(month, ExpenseCategory.installment),
      sampleInstallmentsAfterClose,
    );
    expect(expensesOf(month, ExpenseCategory.variable), isEmpty);
    expect(month.summary.income, brl('4.800,00'));
    expect(month.summary.fixedTotal, brl('2.504,00'));
    expect(month.summary.installmentTotal, brl('790,50'));
    expect(month.summary.variableTotal, brl('0,00'));
    expect(month.summary.balance, brl('1.505,50'));
  });

  test('AT2: a month of variable expenses, batch by batch', () async {
    await cycle.closeTheFirstMonth();

    for (var index = 0; index < sampleVariableBatches.length; index++) {
      for (final expense in sampleVariableBatches[index]) {
        await cycle.save(expense);
      }
      final month = await cycle.openMonth();
      expect(
        month.summary.balance,
        brl(sampleBalancesAfterEachBatch[index]),
        reason: 'balance after batch ${index + 1}',
      );
    }
    final month = await cycle.openMonth();
    expect(month.summary.variableTotal, brl('935,00'));
  });

  test('AT3: the next close, keeping the income', () async {
    await cycle.closeTheFirstMonth();
    await cycle.addTheVariables();
    final closingId = (await cycle.openMonth()).id;

    await cycle.confirmClose(await cycle.plan());

    final month = await cycle.openMonth();
    expect(month.reference, ReferenceMonth(2026, 12));
    expect(month.income, brl('4.800,00'));
    expect(expensesOf(month, ExpenseCategory.installment), [
      installment('Curso de inglês', '250,00', 4, 4),
      installment('TV', '120,00', 9, 18),
      installment('Óculos', '95,50', 4, 4),
      installment('Notebook', '150,00', 8, 10),
      installment('Monitor', '60,00', 8, 9),
    ]);
    expect(month.summary.installmentTotal, brl('675,50'));
    expect(month.summary.fixedTotal, brl('2.504,00'));
    expect(month.summary.variableTotal, brl('0,00'));
    expect(month.summary.balance, brl('1.620,50'));
    final history = await memory.repository.watchClosedMonths().first;
    final closed = history.firstWhere((overview) => overview.id == closingId);
    expect(closed.summary.balance, brl('570,50'));
  });

  test('AT4: a correction, logged with old and new values', () async {
    await cycle.closeTheFirstMonth();
    await cycle.addTheVariables();
    final month = await cycle.openMonth();
    final market = month.entries.firstWhere(
      (entry) => entry.expense.name == 'Compras do mês',
    );
    final bread = month.entries.firstWhere(
      (entry) => entry.expense.name == 'Pão',
    );

    await cycle.save(
      variable('Compras do mês', '570,00', on: defaultToday),
      replacingId: market.id,
    );
    await cycle.delete(bread.id);

    final corrected = await cycle.openMonth();
    expect(corrected.summary.variableTotal, brl('978,00'));
    expect(corrected.summary.balance, brl('527,50'));
    final log = (await memory.repository.snapshot()).changeLog;
    final update = log.lastWhere(
      (entry) => entry.action == ChangeAction.expenseUpdated,
    );
    final deletion = log.last;
    expect(jsonDecode(update.before!), containsPair('amountCents', 52000));
    expect(jsonDecode(update.after!), containsPair('amountCents', 57000));
    expect(deletion.action, ChangeAction.expenseDeleted);
    expect(jsonDecode(deletion.before!), containsPair('name', 'Pão'));
  });

  test('AT5: the over-balance boundary', () async {
    await cycle.closeTheFirstMonth();
    await cycle.addTheVariables();
    final month = await cycle.openMonth();
    expect(month.summary.balance, brl('570,50'));

    expect(
      ExpenseRules.warnings(
        variable('Geladeira', '570,50', on: defaultToday),
        month: month,
      ),
      isEmpty,
    );
    expect(
      ExpenseRules.warnings(
        variable('Geladeira', '570,51', on: defaultToday),
        month: month,
      ),
      {ExpenseWarning.exceedsBalance},
    );
  });
}
