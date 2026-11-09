import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month_summary.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/formatters.dart';

import '../support/builders.dart';
import '../support/sample_cycle.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  group('formatMoney', () {
    test('uses reais, thousands dots and two decimals', () {
      expect(formatMoney(brl('1.234,50')), r'R$ 1.234,50');
      expect(formatMoney(Money.zero), r'R$ 0,00');
      expect(formatMoney(const Money(5)), r'R$ 0,05');
      expect(formatMoney(const Money(100000)), r'R$ 1.000,00');
      expect(formatMoney(Money.max), r'R$ 999.999.999,99');
    });

    test('puts the sign before the currency', () {
      expect(formatMoney(brl('-50,00')), r'-R$ 50,00');
      expect(formatMoney(const Money(-123456789)), r'-R$ 1.234.567,89');
    });
  });

  test('formatAmount has no currency, as in the audit line', () {
    expect(formatAmount(brl('2.504,00')), '2.504,00');
    expect(formatAmount(brl('-0,01')), '-0,01');
  });

  test('formatDate is dd/MM/yyyy', () {
    expect(formatDate(CalendarDate(2026, 3, 9)), '09/03/2026');
  });

  test('formatReference is the pt-BR month and the year', () {
    expect(
      [
        for (var month = 1; month <= 12; month++)
          formatReference(ReferenceMonth(2026, month), l10n),
      ],
      [
        'jan/2026',
        'fev/2026',
        'mar/2026',
        'abr/2026',
        'mai/2026',
        'jun/2026',
        'jul/2026',
        'ago/2026',
        'set/2026',
        'out/2026',
        'nov/2026',
        'dez/2026',
      ],
    );
    expect(formatReference(ReferenceMonth(2026, 12).next(), l10n), 'jan/2027');
  });

  group('formatAuditLine', () {
    test('formats the line of a month after the close', () {
      final summary = MonthSummary.of(
        income: brl('4.800,00'),
        expenses: [...sampleFixedExpenses, ...sampleInstallmentsAfterClose],
      );

      expect(
        formatAuditLine(summary),
        '4.800,00 - (2.504,00 + 790,50 + 0,00) = 1.505,50',
      );
    });

    test('shows a negative balance with its sign', () {
      final summary = MonthSummary.of(
        income: brl('100,00'),
        expenses: [variable('Mercado', '150,00')],
      );

      expect(
        formatAuditLine(summary),
        '100,00 - (0,00 + 0,00 + 150,00) = -50,00',
      );
    });

    test('is empty while the income is missing', () {
      expect(
        formatAuditLine(MonthSummary.of(income: null, expenses: const [])),
        isEmpty,
      );
    });
  });
}
