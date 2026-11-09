import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/domain/month_closing.dart';

import 'app_harness.dart';
import 'builders.dart';
import 'memory_repository.dart';
import 'sample_cycle.dart';

Future<void> seedSampleMonth(MemoryRepository memory) async {
  await memory.repository.setIncome(brl('4.800,00'));
  for (final expense in [
    ...sampleFixedExpenses,
    ...sampleInstallmentsAfterClose,
  ]) {
    await memory.repository.addExpense(expense);
  }
}

Future<void> seedRent(MemoryRepository memory) async {
  await memory.repository.setIncome(brl('1.000,00'));
  await memory.repository.addExpense(fixed('Condomínio', '750,00'));
}

Future<void> closeNovember(MemoryRepository memory) async {
  await memory.repository.setIncome(brl('1.000,00'));
  final outcome = PrepareClose(memory.clock.call)(
    await memory.repository.openMonth(),
  );
  await memory.repository.applyClose((outcome as ClosePlanned).plan);
}

Seed failingOn(String table, [Seed? before]) => (memory) async {
  await before?.call(memory);
  await memory.database.customStatement(
    'CREATE TRIGGER fail_$table BEFORE INSERT ON $table '
    "BEGIN SELECT RAISE(ABORT, 'forced'); END",
  );
};
