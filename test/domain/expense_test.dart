import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/expense.dart';

import '../support/builders.dart';

void main() {
  group('Expense', () {
    test('knows its category', () {
      expect(fixed('Condomínio', '750,00').category, ExpenseCategory.fixed);
      expect(
        installment('Monitor', '60,00', 7, 9).category,
        ExpenseCategory.installment,
      );
      expect(variable('Pão', '7,00').category, ExpenseCategory.variable);
    });

    test('an installment knows when it is the last one', () {
      expect(installment('Monitor', '60,00', 9, 9).isLast, isTrue);
      expect(installment('Monitor', '60,00', 8, 9).isLast, isFalse);
    });

    test('an installment knows how many are left after the current one', () {
      expect(installment('Monitor', '60,00', 7, 9).remaining, 2);
      expect(installment('Monitor', '60,00', 9, 9).remaining, 0);
    });

    test('an installment advances one step keeping name and amount', () {
      expect(
        installment('Monitor', '60,00', 7, 9).advanced(),
        installment('Monitor', '60,00', 8, 9),
      );
    });

    test('an expense can take another name, keeping everything else', () {
      expect(
        fixed('condomínio', '750,00').withName('Condomínio'),
        fixed('Condomínio', '750,00'),
      );
      expect(
        installment('monitor', '60,00', 7, 9).withName('Monitor'),
        installment('Monitor', '60,00', 7, 9),
      );
      expect(
        variable('pão', '7,00', on: defaultToday).withName('Pão'),
        variable('Pão', '7,00', on: defaultToday),
      );
    });

    test('expenses are values', () {
      expect(
        {fixed('Condomínio', '750,00'), fixed('Condomínio', '750,00')},
        hasLength(1),
      );
      expect(
        {
          installment('Monitor', '60,00', 7, 9),
          installment('Monitor', '60,00', 7, 9),
        },
        hasLength(1),
      );
      expect(
        {
          variable('Pão', '7,00', on: defaultToday),
          variable('Pão', '7,00', on: defaultToday),
        },
        hasLength(1),
      );
      expect(
        fixed('Condomínio', '750,00'),
        isNot(variable('Condomínio', '750,00')),
      );
    });

    test('expenses describe themselves for diagnostics', () {
      expect(fixed('Condomínio', '750,00').toString(), contains('Condomínio'));
      expect(installment('Monitor', '60,00', 7, 9).toString(), contains('7/9'));
      expect(variable('Pão', '7,00').toString(), contains('Pão'));
    });
  });

  group('ExpenseEntry', () {
    test('is a value with identity and creation time', () {
      expect(
        {
          entry(1, fixed('Condomínio', '750,00')),
          entry(1, fixed('Condomínio', '750,00')),
        },
        hasLength(1),
      );
      expect(
        entry(1, fixed('Condomínio', '750,00')).toString(),
        contains('#1'),
      );
    });
  });
}
