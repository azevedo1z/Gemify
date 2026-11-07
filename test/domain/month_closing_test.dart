import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/reference_month.dart';

import '../support/builders.dart';
import '../support/sample_cycle.dart';

ClosePlan planOf(CloseOutcome outcome) => switch (outcome) {
  ClosePlanned(:final plan) => plan,
  CloseRejected() => throw StateError('Expected a plan, got $outcome'),
};

CloseRejected rejectionOf(CloseOutcome outcome) => switch (outcome) {
  final CloseRejected rejection => rejection,
  ClosePlanned() => throw StateError('Expected a rejection, got $outcome'),
};

void main() {
  final november = ReferenceMonth(2026, 11);
  final december = ReferenceMonth(2026, 12);

  group('MonthClosing.plan, the close of a full month', () {
    final month = openMonth(
      reference: ReferenceMonth(2026, 10),
      income: brl('5.000,00'),
      items: entries([
        ...sampleFixedExpenses,
        ...sampleInstallmentsBeforeClose,
        variable('Mercado', '300,00', on: defaultToday),
      ]),
    );

    final plan = planOf(
      MonthClosing.plan(
        month: month,
        newReference: november,
        newIncome: brl('4.800,00'),
        today: defaultToday,
      ),
    );

    test('carries Fixed items and advances unfinished installments', () {
      expect(plan.newExpenses, [
        ...sampleFixedExpenses,
        ...sampleInstallmentsAfterClose,
      ]);
    });

    test('drops purchases on their last installment and Variable items', () {
      expect(
        [for (final installment in plan.finishing) installment.name],
        ['Conserto do celular', 'Fone de ouvido'],
      );
      expect(
        [for (final entry in plan.clearedVariables) entry.expense.name],
        ['Mercado'],
      );
    });

    test('describes every step for the preview', () {
      expect(plan.closingMonthId, month.id);
      expect(plan.closingReference, ReferenceMonth(2026, 10));
      expect(plan.newReference, november);
      expect(plan.keptFixed, hasLength(11));
      expect(
        [
          for (final step in plan.advancing)
            '${step.from.current}/${step.to.current}',
        ],
        ['2/3', '7/8', '2/3', '9/10', '6/7', '6/7', '6/7'],
      );
      expect(plan.closingSummary, month.summary);
    });

    test('opens the new month with the informed income', () {
      expect(plan.newIncome, brl('4.800,00'));
      expect(plan.incomeKept, isFalse);
    });
  });

  group('MonthClosing.plan, income of the new month', () {
    final month = openMonth(income: brl('4.800,00'));

    test('keeps the closing income when none is informed', () {
      final plan = planOf(
        MonthClosing.plan(
          month: month,
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(plan.newIncome, brl('4.800,00'));
      expect(plan.incomeKept, isTrue);
    });

    test('accepts zero as an informed income', () {
      final plan = planOf(
        MonthClosing.plan(
          month: month,
          newReference: december,
          newIncome: Money.zero,
          today: defaultToday,
        ),
      );

      expect(plan.newIncome, Money.zero);
      expect(plan.incomeKept, isFalse);
    });

    test('rejects an income above the cap', () {
      final rejection = rejectionOf(
        MonthClosing.plan(
          month: month,
          newReference: december,
          newIncome: Money.max + const Money(1),
          today: defaultToday,
        ),
      );

      expect(rejection.errors, {CloseError.newIncomeOutOfRange});
    });
  });

  group('MonthClosing.plan, validation', () {
    test('a month with no items closes into an empty month', () {
      final plan = planOf(
        MonthClosing.plan(
          month: openMonth(income: brl('1,00')),
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(plan.newExpenses, isEmpty);
    });

    test('requires the income of the closing month', () {
      final rejection = rejectionOf(
        MonthClosing.plan(
          month: openMonth(),
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(rejection.errors, {CloseError.incomeMissing});
    });

    test('requires a new reference after the closing one', () {
      final month = openMonth(reference: november, income: brl('1,00'));

      for (final reference in [november, ReferenceMonth(2026, 10)]) {
        expect(
          rejectionOf(
            MonthClosing.plan(
              month: month,
              newReference: reference,
              newIncome: null,
              today: defaultToday,
            ),
          ).errors,
          {CloseError.referenceNotAfterClosing},
        );
      }
    });

    test('accepts skipping months', () {
      final plan = planOf(
        MonthClosing.plan(
          month: openMonth(reference: november, income: brl('1,00')),
          newReference: ReferenceMonth(2027, 1),
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(plan.newReference, ReferenceMonth(2027, 1));
    });

    test('lists the invalid items that block the close', () {
      final rejection = rejectionOf(
        MonthClosing.plan(
          month: openMonth(
            income: brl('1,00'),
            items: [
              entry(1, fixed('Condomínio', '750,00')),
              entry(2, installment('TV', '120,00', 19, 18)),
              entry(3, variable('Pão', '7,00')),
            ],
          ),
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(rejection.errors, {CloseError.invalidExpenses});
      expect(rejection.invalidEntries, {
        2: {ExpenseError.installmentCurrentOutOfRange},
        3: {ExpenseError.dateMissing},
      });
    });

    test('refuses a month that is already closed', () {
      final rejection = rejectionOf(
        MonthClosing.plan(
          month: closedMonth(reference: november),
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ),
      );

      expect(rejection.errors, {CloseError.monthNotOpen});
    });

    test('outcomes describe themselves for diagnostics', () {
      final outcome = MonthClosing.plan(
        month: openMonth(),
        newReference: december,
        newIncome: null,
        today: defaultToday,
      );

      expect(outcome.toString(), contains('incomeMissing'));
      expect(
        MonthClosing.plan(
          month: openMonth(income: brl('1,00')),
          newReference: december,
          newIncome: null,
          today: defaultToday,
        ).toString(),
        contains('2026-12'),
      );
    });
  });
}
