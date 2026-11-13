import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/application/clock.dart';
import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/application/rejections.dart';
import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/reference_month.dart';

import '../support/builders.dart';
import '../support/memory_repository.dart';

void main() {
  late MemoryRepository memory;

  setUp(() async => memory = await MemoryRepository.open());
  tearDown(() => memory.close());

  test('the first month is the one that contains today', () async {
    final fresh = await MemoryRepository.open(
      firstMonth: ReferenceMonth(2000, 1),
    );
    addTearDown(fresh.close);
    await fresh.database.delete(fresh.database.months).go();

    await StartMonth(fresh.repository, fresh.clock.call)();

    expect(
      (await fresh.repository.openMonth()).reference,
      ReferenceMonth(2026, 11),
    );
  });

  final lateEvening = DateTime.utc(2026, 11, 8, 1);

  test(
    'today is the local date of the clock, not the UTC one',
    () => expect(todayFrom(() => lateEvening), CalendarDate(2026, 11, 7)),
    skip: lateEvening.toLocal().day == lateEvening.day
        ? 'Needs a time zone behind UTC, such as TZ=America/Sao_Paulo'
        : false,
  );

  group('CheckExpense', () {
    late CheckExpense check;

    setUp(() => check = CheckExpense(memory.repository, memory.clock.call));

    test('returns the cleaned expense and its errors', () async {
      final result = await check(installment('  TV   Sala ', '0,00', 1, 1));

      expect(result.expense, installment('TV Sala', '0,00', 1, 1));
      expect(result.errors, {
        ExpenseError.amountNotPositive,
        ExpenseError.installmentTotalBelowMinimum,
      });
      expect(result.isValid, isFalse);
      expect(result.warnings, isEmpty);
    });

    test('warns against the open month, counting only the increase', () async {
      await memory.repository.setIncome(brl('1.000,00'));
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));
      final original = (await memory.repository.openMonth()).entries.single;

      final result = await check(
        fixed('Condomínio', '1.100,00'),
        original: original,
      );

      expect(result.isValid, isTrue);
      expect(result.warnings, {ExpenseWarning.exceedsBalance});
      expect(result.addedAmount, brl('350,00'));
      expect(result.balance, brl('250,00'));
    });

    test('warns about a possible duplicate of a new item', () async {
      await memory.repository.addExpense(fixed('Condomínio', '750,00'));

      final result = await check(fixed(' condomínio ', '10,00'));

      expect(result.warnings, {ExpenseWarning.possibleDuplicate});
    });
  });

  group('SaveExpense', () {
    test('cleans the name before storing', () async {
      await SaveExpense(memory.repository, memory.clock.call)(
        fixed('  Conta   de Luz ', '120,00'),
      );

      expect(
        (await memory.repository.openMonth()).entries.single.expense.name,
        'Conta de Luz',
      );
    });

    test('rejects an invalid expense without writing', () async {
      await expectLater(
        SaveExpense(memory.repository, memory.clock.call)(
          installment('TV', '0,00', 1, 1),
        ),
        throwsA(
          isA<InvalidExpenseException>().having(
            (rejection) => rejection.errors,
            'errors',
            {
              ExpenseError.amountNotPositive,
              ExpenseError.installmentTotalBelowMinimum,
            },
          ),
        ),
      );

      expect((await memory.repository.openMonth()).entries, isEmpty);
    });

    test('replaces an existing item', () async {
      final save = SaveExpense(memory.repository, memory.clock.call);
      await save(fixed('Condomínio', '750,00'));
      final id = (await memory.repository.openMonth()).entries.single.id;

      await save(fixed('Condomínio', '800,00'), replacingId: id);

      expect(
        (await memory.repository.openMonth()).entries.single.expense,
        fixed('Condomínio', '800,00'),
      );
    });
  });

  test('DeleteExpense removes the item', () async {
    await SaveExpense(memory.repository, memory.clock.call)(
      fixed('Condomínio', '750,00'),
    );
    final id = (await memory.repository.openMonth()).entries.single.id;

    await DeleteExpense(memory.repository)(id);

    expect((await memory.repository.openMonth()).entries, isEmpty);
  });

  group('SetIncome', () {
    test('accepts zero and stores it', () async {
      await SetIncome(memory.repository)(Money.zero);

      expect((await memory.repository.openMonth()).income, Money.zero);
    });

    test('rejects a negative income', () async {
      await expectLater(
        SetIncome(memory.repository)(const Money(-1)),
        throwsA(isA<InvalidIncomeException>()),
      );
    });

    test('rejects an income above the cap without writing', () async {
      await expectLater(
        SetIncome(memory.repository)(Money.max + const Money(1)),
        throwsA(isA<InvalidIncomeException>()),
      );

      expect((await memory.repository.openMonth()).income, isNull);
    });
  });

  group('ChangeOpenReference', () {
    Future<void> closeNovemberThroughUseCases() async {
      await SetIncome(memory.repository)(brl('1,00'));
      final outcome = PrepareClose(memory.clock.call)(
        await memory.repository.openMonth(),
      );
      await ConfirmClose(memory.repository)(planOf(outcome));
    }

    ChangeOpenReference changeReference() =>
        ChangeOpenReference(memory.repository, memory.clock.call);

    test('offers the window around today while nothing was closed', () async {
      final window = await changeReference().window();

      expect(window.first, ReferenceMonth(2025, 11));
      expect(window.last, ReferenceMonth(2027, 2));
    });

    test('accepts a past month while nothing was closed', () async {
      await changeReference()(ReferenceMonth(2025, 11));

      expect(
        (await memory.repository.openMonth()).reference,
        ReferenceMonth(2025, 11),
      );
    });

    test('rejects a month outside the window', () async {
      for (final reference in [
        ReferenceMonth(2025, 10),
        ReferenceMonth(2027, 3),
      ]) {
        await expectLater(
          changeReference()(reference),
          throwsA(isA<InvalidReferenceException>()),
        );
      }
      expect(
        (await memory.repository.openMonth()).reference,
        ReferenceMonth(2026, 11),
      );
    });

    test('rejects a month not after the latest closed one', () async {
      await closeNovemberThroughUseCases();

      await expectLater(
        changeReference()(ReferenceMonth(2026, 11)),
        throwsA(isA<InvalidReferenceException>()),
      );
      await changeReference()(ReferenceMonth(2027, 1));
      expect(
        (await memory.repository.openMonth()).reference,
        ReferenceMonth(2027, 1),
      );
    });
  });

  test(
    'PrepareClose defaults to the next month and keeps the income',
    () async {
      await SetIncome(memory.repository)(brl('4.800,00'));

      final outcome = PrepareClose(memory.clock.call)(
        await memory.repository.openMonth(),
      );

      final plan = planOf(outcome);
      expect(plan.newReference, ReferenceMonth(2026, 12));
      expect(plan.newIncome, brl('4.800,00'));
      expect(plan.incomeKept, isTrue);
    },
  );

  test('PrepareClose offers the months after the closing one', () async {
    final window = PrepareClose(memory.clock.call).window(
      await memory.repository.openMonth(),
    );

    expect(window.first, ReferenceMonth(2026, 12));
    expect(window.last, ReferenceMonth(2027, 2));
  });

  test('rejections describe themselves for diagnostics', () {
    expect(
      const InvalidExpenseException({ExpenseError.nameEmpty}).toString(),
      contains('nameEmpty'),
    );
    expect(const InvalidIncomeException(Money(-1)).toString(), contains('-1'));
    expect(
      InvalidReferenceException(ReferenceMonth(2026, 1)).toString(),
      contains('2026-01'),
    );
  });
}
