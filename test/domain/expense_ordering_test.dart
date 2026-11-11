import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/expense_ordering.dart';

import '../support/builders.dart';

List<int> idsOf(List<ExpenseEntry> entries) => [
  for (final entry in entries) entry.id,
];

void main() {
  group('ExpenseOrdering', () {
    test('groups by category in the fixed order', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, variable('Pão', '7,00', on: defaultToday)),
        entry(2, installment('Monitor', '60,00', 7, 9)),
        entry(3, fixed('Condomínio', '750,00')),
      ]);

      expect(idsOf(sorted), [3, 2, 1]);
    });

    test('sorts Fixed alphabetically, ignoring case and accents', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, fixed('Energia', '180,00')),
        entry(2, fixed('aluguel', '1.100,00')),
        entry(3, fixed('Água', '85,00')),
      ]);

      expect(idsOf(sorted), [3, 2, 1]);
    });

    test('sorts Installments by how many are left, ending soonest first', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, installment('Armário', '70,00', 2, 12)),
        entry(2, installment('Notebook', '150,00', 10, 10)),
        entry(3, installment('Monitor', '60,00', 7, 9)),
      ]);

      expect(idsOf(sorted), [2, 3, 1]);
    });

    test('sorts Variable by date, oldest first, with the undated last', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, variable('Mercado', '1,00', on: CalendarDate(2026, 11, 7))),
        entry(2, variable('Sem data', '1,00')),
        entry(3, variable('Pão', '1,00', on: CalendarDate(2026, 11, 5))),
      ]);

      expect(idsOf(sorted), [3, 1, 2]);
    });

    test('breaks a tie by id, oldest entry first', () {
      final sorted = ExpenseOrdering.sorted([
        entry(8, variable('Sem data', '1,00')),
        entry(7, variable('Sem data', '1,00')),
        entry(6, variable('Pão', '7,00', on: defaultToday)),
        entry(5, variable('Pão', '7,00', on: defaultToday)),
        entry(4, installment('Monitor', '60,00', 7, 9)),
        entry(3, installment('Armário', '70,00', 1, 3)),
        entry(2, fixed('Academia', '120,00')),
        entry(1, fixed('academia', '120,00')),
      ]);

      expect(idsOf(sorted), [1, 2, 3, 4, 5, 6, 7, 8]);
    });
  });
}
