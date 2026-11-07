import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:gemify/data/drift_month_repository.dart';
import 'package:gemify/data/gemify_database.dart';
import 'package:gemify/domain/reference_month.dart';

final class TestClock {
  TestClock([DateTime? start]) : now = start ?? DateTime.utc(2026, 11, 7, 12);

  DateTime now;

  DateTime call() => now;

  void advance([Duration step = const Duration(minutes: 1)]) =>
      now = now.add(step);
}

final class MemoryRepository {
  MemoryRepository._(this.database, this.clock, this.repository);

  static Future<MemoryRepository> open({ReferenceMonth? firstMonth}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final database = GemifyDatabase(NativeDatabase.memory());
    final clock = TestClock();
    final repository = DriftMonthRepository(database, clock: clock.call);
    await repository.ensureOpenMonth(firstMonth ?? ReferenceMonth(2026, 11));
    return MemoryRepository._(database, clock, repository);
  }

  final GemifyDatabase database;
  final TestClock clock;
  final DriftMonthRepository repository;

  Future<void> close() => database.close();
}
