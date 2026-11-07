import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/expense_ordering.dart';

import '../support/builders.dart';

List<int> idsOf(List<ExpenseEntry> entries) => [
  for (final entry in entries) entry.id,
];

void main() {
  group('ExpenseOrdering', () {
    test('groups by category in the Gem order', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, variable('Pão', '7,00', on: defaultToday)),
        entry(2, installment('Monitor', '60,00', 7, 9)),
        entry(3, fixed('Condomínio', '750,00')),
      ]);

      expect(idsOf(sorted), [3, 2, 1]);
    });

    test('sorts Fixed and Installments alphabetically, ignoring case and '
        'accents', () {
      final sorted = ExpenseOrdering.sorted([
        entry(1, fixed('Energia', '180,00')),
        entry(2, fixed('aluguel', '1.100,00')),
        entry(3, fixed('Água', '85,00')),
        entry(4, installment('Notebook', '150,00', 7, 10)),
        entry(5, installment('Armário', '70,00', 10, 10)),
      ]);

      expect(idsOf(sorted), [3, 2, 1, 5, 4]);
    });

    test('sorts Variable by date, newest first, then latest added', () {
      final sorted = ExpenseOrdering.sorted([
        entry(
          1,
          variable('A', '1,00', on: CalendarDate(2026, 11, 5)),
          createdAt: DateTime.utc(2026, 11, 7, 10),
        ),
        entry(
          2,
          variable('B', '1,00', on: CalendarDate(2026, 11, 7)),
          createdAt: DateTime.utc(2026, 11, 7, 9),
        ),
        entry(
          3,
          variable('C', '1,00', on: CalendarDate(2026, 11, 5)),
          createdAt: DateTime.utc(2026, 11, 7, 11),
        ),
        entry(4, variable('D', '1,00')),
      ]);

      expect(idsOf(sorted), [2, 3, 1, 4]);
    });

    test('breaks any remaining tie by id, so the order is stable', () {
      final sorted = ExpenseOrdering.sorted([
        entry(2, fixed('Academia', '120,00')),
        entry(1, fixed('academia', '120,00')),
        entry(3, variable('Pão', '7,00', on: defaultToday)),
        entry(4, variable('Pão', '7,00', on: defaultToday)),
        entry(5, variable('Sem data', '1,00')),
        entry(6, variable('Sem data', '1,00')),
      ]);

      expect(idsOf(sorted), [1, 2, 4, 3, 6, 5]);
    });
  });
}
