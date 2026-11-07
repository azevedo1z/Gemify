import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/month_summary.dart';

import '../support/builders.dart';
import '../support/sample_cycle.dart';

void main() {
  group('MonthSummary', () {
    test('adds each category and derives the balance', () {
      final summary = MonthSummary.of(
        income: brl('4.800,00'),
        expenses: [
          ...sampleFixedExpenses,
          ...sampleInstallmentsAfterClose,
          for (final batch in sampleVariableBatches) ...batch,
        ],
      );

      expect(summary.fixedTotal, brl('2.504,00'));
      expect(summary.installmentTotal, brl('790,50'));
      expect(summary.variableTotal, brl('935,00'));
      expect(summary.totalExpenses, brl('4.229,50'));
      expect(summary.balance, brl('570,50'));
    });

    test('has no balance while the income is missing', () {
      final summary = MonthSummary.of(
        income: null,
        expenses: [fixed('Condomínio', '750,00')],
      );

      expect(summary.totalExpenses, brl('750,00'));
      expect(summary.balance, isNull);
    });

    test('goes negative when expenses exceed the income', () {
      final summary = MonthSummary.of(
        income: brl('100,00'),
        expenses: [variable('Mercado', '150,00')],
      );

      expect(summary.balance, brl('-50,00'));
    });

    test('is zero for a month without expenses', () {
      final summary = MonthSummary.of(income: brl('0,00'), expenses: const []);

      expect(summary.totalExpenses, brl('0,00'));
      expect(summary.balance, brl('0,00'));
    });

    test('is a value', () {
      MonthSummary summaryOf(String income) => MonthSummary.of(
        income: brl(income),
        expenses: [fixed('Condomínio', '750,00')],
      );

      expect({summaryOf('1.000,00'), summaryOf('1.000,00')}, hasLength(1));
      expect(summaryOf('1.000,00'), isNot(summaryOf('2.000,00')));
    });

    test('a month summarizes its own entries', () {
      final month = openMonth(
        income: brl('1.000,00'),
        items: entries([
          fixed('Condomínio', '750,00'),
          variable('Pão', '7,00'),
        ]),
      );

      expect(month.summary.balance, brl('243,00'));
      expect(month.isOpen, isTrue);
    });
  });
}
