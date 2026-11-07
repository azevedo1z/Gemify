import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_actions.dart';
import 'package:gemify/application/rejections.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/reference_month.dart';

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
              ExpenseError.installmentTotalBelowTwo,
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
    Future<void> closeNovember() async {
      await SetIncome(memory.repository)(brl('1,00'));
      final outcome = PrepareClose(memory.clock.call)(
        await memory.repository.openMonth(),
      );
      await ConfirmClose(memory.repository)((outcome as ClosePlanned).plan);
    }

    test('accepts any month while nothing was closed', () async {
      await ChangeOpenReference(memory.repository)(ReferenceMonth(2020, 1));

      expect(
        (await memory.repository.openMonth()).reference,
        ReferenceMonth(2020, 1),
      );
    });

    test('rejects a month not after the latest closed one', () async {
      await closeNovember();

      await expectLater(
        ChangeOpenReference(memory.repository)(ReferenceMonth(2026, 11)),
        throwsA(isA<InvalidReferenceException>()),
      );
      await ChangeOpenReference(memory.repository)(ReferenceMonth(2027, 1));
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

      final plan = (outcome as ClosePlanned).plan;
      expect(plan.newReference, ReferenceMonth(2026, 12));
      expect(plan.newIncome, brl('4.800,00'));
      expect(plan.incomeKept, isTrue);
    },
  );

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
