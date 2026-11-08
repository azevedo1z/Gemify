import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';

import '../support/builders.dart';

Set<ExpenseError> errorsInOpenMonth(Expense expense) => ExpenseRules.errors(
  expense,
  status: MonthStatus.open,
  today: defaultToday,
);

void main() {
  group('ExpenseRules.errors', () {
    test('accepts valid expenses of every category', () {
      expect(errorsInOpenMonth(fixed('Condomínio', '750,00')), isEmpty);
      expect(errorsInOpenMonth(installment('TV', '120,00', 8, 18)), isEmpty);
      expect(
        errorsInOpenMonth(variable('Pão', '7,00', on: defaultToday)),
        isEmpty,
      );
    });

    test('requires a name of 1 to 80 characters after cleaning', () {
      expect(
        errorsInOpenMonth(fixed('   ', '1,00')),
        {ExpenseError.nameEmpty},
      );
      expect(errorsInOpenMonth(fixed('a' * 80, '1,00')), isEmpty);
      expect(
        errorsInOpenMonth(fixed('a' * 81, '1,00')),
        {ExpenseError.nameTooLong},
      );
      expect(errorsInOpenMonth(fixed('  ${'a' * 80}  ', '1,00')), isEmpty);
    });

    test('counts an emoji in the name as one character', () {
      expect(errorsInOpenMonth(fixed('🛒' * 80, '1,00')), isEmpty);
      expect(
        errorsInOpenMonth(fixed('🛒' * 81, '1,00')),
        {ExpenseError.nameTooLong},
      );
    });

    test('requires an amount above zero and up to the cap', () {
      expect(
        errorsInOpenMonth(fixed('Aluguel', '0,00')),
        {ExpenseError.amountNotPositive},
      );
      expect(
        errorsInOpenMonth(fixed('Aluguel', '-1,00')),
        {ExpenseError.amountNotPositive},
      );
      expect(
        errorsInOpenMonth(
          const FixedExpense(name: 'Aluguel', amount: Money.max),
        ),
        isEmpty,
      );
      expect(
        errorsInOpenMonth(
          FixedExpense(name: 'Aluguel', amount: Money.max + const Money(1)),
        ),
        {ExpenseError.amountAboveMax},
      );
    });

    test('requires at least two installments and a current within range', () {
      expect(
        errorsInOpenMonth(installment('TV', '1,00', 1, 1)),
        {ExpenseError.installmentTotalBelowMinimum},
      );
      expect(
        errorsInOpenMonth(installment('TV', '1,00', 0, 10)),
        {ExpenseError.installmentCurrentOutOfRange},
      );
      expect(
        errorsInOpenMonth(installment('TV', '1,00', 11, 10)),
        {ExpenseError.installmentCurrentOutOfRange},
      );
      expect(
        errorsInOpenMonth(installment('Fone de ouvido', '90,00', 2, 2)),
        isEmpty,
      );
    });

    test('requires a date not after today in the open month', () {
      expect(
        errorsInOpenMonth(variable('Pão', '7,00')),
        {ExpenseError.dateMissing},
      );
      expect(
        errorsInOpenMonth(
          variable('Pão', '7,00', on: CalendarDate(2026, 11, 8)),
        ),
        {ExpenseError.dateInFuture},
      );
    });

    test('accepts a missing date only in a closed month', () {
      expect(
        ExpenseRules.errors(
          variable('Pão', '7,00'),
          status: MonthStatus.closed,
          today: defaultToday,
        ),
        isEmpty,
      );
      expect(
        ExpenseRules.errors(
          variable('Pão', '7,00', on: CalendarDate(2026, 11, 8)),
          status: MonthStatus.closed,
          today: defaultToday,
        ),
        {ExpenseError.dateInFuture},
      );
    });
  });

  test('ExpenseRules.cleaned cleans the name and keeps the rest', () {
    expect(
      ExpenseRules.cleaned(installment('  TV   Sala ', '120,00', 8, 18)),
      installment('TV Sala', '120,00', 8, 18),
    );
  });

  group('ExpenseRules.warnings, over balance', () {
    final month = openMonth(
      income: brl('1.000,00'),
      items: [
        entry(1, variable('Compras no mercado', '600,00', on: defaultToday)),
      ],
    );

    test('a new expense that leaves the balance at zero raises nothing', () {
      expect(
        ExpenseRules.warnings(
          variable('Feira', '400,00', on: defaultToday),
          month: month,
        ),
        isEmpty,
      );
    });

    test('a new expense one cent above the balance raises a warning', () {
      expect(
        ExpenseRules.warnings(
          variable('Feira', '400,01', on: defaultToday),
          month: month,
        ),
        {ExpenseWarning.exceedsBalance},
      );
    });

    test('an edit compares only the increase', () {
      final original = month.entries.single;

      expect(
        ExpenseRules.warnings(
          variable('Compras no mercado', '1.000,00', on: defaultToday),
          month: month,
          original: original,
        ),
        isEmpty,
      );
      expect(
        ExpenseRules.warnings(
          variable('Compras no mercado', '1.000,01', on: defaultToday),
          month: month,
          original: original,
        ),
        {ExpenseWarning.exceedsBalance},
      );
    });

    test('with the balance already negative, every new expense warns', () {
      final negative = openMonth(
        income: brl('100,00'),
        items: [entry(1, variable('Mercado', '150,00', on: defaultToday))],
      );

      expect(
        ExpenseRules.warnings(
          variable('Pão', '0,01', on: defaultToday),
          month: negative,
        ),
        {ExpenseWarning.exceedsBalance},
      );
    });

    test('with the balance negative, edits that add nothing never warn', () {
      final negative = openMonth(
        income: brl('100,00'),
        items: [entry(1, variable('Mercado', '150,00', on: defaultToday))],
      );
      final original = negative.entries.single;

      expect(
        ExpenseRules.warnings(
          variable('Supermercado', '150,00', on: defaultToday),
          month: negative,
          original: original,
        ),
        isEmpty,
      );
      expect(
        ExpenseRules.warnings(
          variable('Mercado', '120,00', on: defaultToday),
          month: negative,
          original: original,
        ),
        isEmpty,
      );
    });

    test('adds the whole amount, or only the increase of an edit', () {
      final original = month.entries.single;

      expect(
        ExpenseRules.addedAmount(variable('Feira', '400,00', on: defaultToday)),
        brl('400,00'),
      );
      expect(
        ExpenseRules.addedAmount(
          variable('Compras no mercado', '650,00', on: defaultToday),
          original: original,
        ),
        brl('50,00'),
      );
      expect(
        ExpenseRules.addedAmount(
          variable('Compras no mercado', '550,00', on: defaultToday),
          original: original,
        ),
        brl('-50,00'),
      );
    });

    test('there is no balance check while the income is missing', () {
      expect(
        ExpenseRules.warnings(
          variable('Pão', '7,00', on: defaultToday),
          month: openMonth(),
        ),
        isEmpty,
      );
    });
  });

  group('ExpenseRules.warnings, possible duplicate', () {
    final month = openMonth(
      income: brl('10.000,00'),
      items: [
        entry(1, fixed('Academia', '120,00')),
        entry(2, installment('Monitor', '60,00', 7, 9)),
        entry(3, variable('Pão', '7,00', on: defaultToday)),
      ],
    );

    test('a Fixed or Installment name repeated in either category', () {
      expect(
        ExpenseRules.warnings(fixed(' academia ', '99,00'), month: month),
        {ExpenseWarning.possibleDuplicate},
      );
      expect(
        ExpenseRules.warnings(
          installment('Academia', '99,00', 1, 12),
          month: month,
        ),
        {ExpenseWarning.possibleDuplicate},
      );
      expect(
        ExpenseRules.warnings(fixed('Monitor', '10,00'), month: month),
        {ExpenseWarning.possibleDuplicate},
      );
    });

    test('a Variable item with the same name, amount and date', () {
      expect(
        ExpenseRules.warnings(
          variable('pao', '7,00', on: defaultToday),
          month: month,
        ),
        {ExpenseWarning.possibleDuplicate},
      );
      expect(
        ExpenseRules.warnings(
          variable('Pão', '8,00', on: defaultToday),
          month: month,
        ),
        isEmpty,
      );
      expect(
        ExpenseRules.warnings(
          variable('Pão', '7,00', on: CalendarDate(2026, 11, 6)),
          month: month,
        ),
        isEmpty,
      );
    });

    test('Variable and recurring items never match each other', () {
      expect(
        ExpenseRules.warnings(
          variable('Academia', '120,00', on: defaultToday),
          month: month,
        ),
        isEmpty,
      );
      expect(
        ExpenseRules.warnings(fixed('Pão', '7,00'), month: month),
        isEmpty,
      );
    });

    test('an edited item is not compared with itself', () {
      expect(
        ExpenseRules.warnings(
          fixed('Academia', '130,00'),
          month: month,
          original: month.entries.first,
        ),
        isEmpty,
      );
    });
  });
}
