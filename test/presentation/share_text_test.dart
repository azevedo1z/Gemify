import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/share_text.dart';

import '../support/builders.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  test('writes the month in the share layout', () {
    final month = openMonth(
      income: brl('4.800,00'),
      items: entries(<Expense>[
        fixed('Reserva', '600,00'),
        fixed('Aluguel', '1.100,00'),
        installment('TV', '120,00', 8, 18),
        installment('Armário', '70,00', 10, 10),
        variable('Veterinário', '110,00', on: defaultToday),
      ]),
    );

    expect(shareText(month, l10n), r'''
Controle Financeiro - nov/2026

1. Entrada Mensal
Entrada: R$ 4.800,00

2. Gastos Fixos
- Aluguel: R$ 1.100,00
- Reserva: R$ 600,00
Total Gastos Fixos: R$ 1.700,00

3. Gastos Parcelados
- Armário (10/10, Final): R$ 70,00
- TV (8/18): R$ 120,00
Total Gastos Parcelados: R$ 190,00

4. Gastos Variáveis
- Veterinário: R$ 110,00
Total Gastos Variáveis: R$ 110,00

Auditoria de Cálculos
(Entrada) - (Fixos + Parcelados + Variáveis) = Saldo
4.800,00 - (1.700,00 + 190,00 + 110,00) = 2.800,00''');
  });

  test('marks empty sections and a missing income', () {
    final text = shareText(
      openMonth(reference: ReferenceMonth(2027, 1)),
      l10n,
    );

    expect(text, startsWith('Controle Financeiro - jan/2027'));
    expect('Nenhum gasto registrado'.allMatches(text), hasLength(3));
    expect(text, contains('1. Entrada Mensal\nEntrada pendente'));
    expect(text, endsWith('= Saldo\nEntrada pendente'));
  });

  test('keeps the sign of a negative balance', () {
    final text = shareText(
      openMonth(
        income: brl('100,00'),
        items: entries([variable('Mercado', '150,00', on: defaultToday)]),
      ),
      l10n,
    );

    expect(text, endsWith('100,00 - (0,00 + 0,00 + 150,00) = -50,00'));
  });
}
