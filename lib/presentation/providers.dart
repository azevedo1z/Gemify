import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemify/application/backup/backup_actions.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_actions.dart';
import 'package:gemify/application/month_repository.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/presentation/backup/backup_files.dart';
import 'package:gemify/presentation/theme/theme_preference.dart';

final Provider<Clock> clockProvider = Provider((ref) => systemClock);

final Provider<MonthRepository> monthRepositoryProvider = Provider(
  (ref) => throw UnimplementedError('Provide the repository at startup'),
);

final Provider<CalendarDate Function()> todayProvider = Provider((ref) {
  final clock = ref.watch(clockProvider);
  return () => todayFrom(clock);
});

final StreamProvider<Month> openMonthProvider = StreamProvider(
  (ref) => ref.watch(monthRepositoryProvider).watchOpenMonth(),
);

final AutoDisposeStreamProviderFamily<Month, int> monthProvider = StreamProvider
    .autoDispose
    .family<Month, int>(
      (ref, id) => ref.watch(monthRepositoryProvider).watchMonth(id),
    );

final AutoDisposeStreamProvider<List<MonthOverview>> closedMonthsProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(monthRepositoryProvider).watchClosedMonths(),
    );

final AutoDisposeFutureProviderFamily<List<String>, ExpenseCategory>
usedNamesProvider = FutureProvider.autoDispose
    .family<List<String>, ExpenseCategory>(
      (ref, category) => ref.watch(monthRepositoryProvider).usedNames(category),
    );

final Provider<SetIncome> setIncomeProvider = Provider(
  (ref) => SetIncome(ref.watch(monthRepositoryProvider)),
);

final Provider<SaveExpense> saveExpenseProvider = Provider(
  (ref) =>
      SaveExpense(ref.watch(monthRepositoryProvider), ref.watch(clockProvider)),
);

final Provider<DeleteExpense> deleteExpenseProvider = Provider(
  (ref) => DeleteExpense(ref.watch(monthRepositoryProvider)),
);

final Provider<ChangeOpenReference> changeOpenReferenceProvider = Provider(
  (ref) => ChangeOpenReference(ref.watch(monthRepositoryProvider)),
);

final Provider<PrepareClose> prepareCloseProvider = Provider(
  (ref) => PrepareClose(ref.watch(clockProvider)),
);

final Provider<ConfirmClose> confirmCloseProvider = Provider(
  (ref) => ConfirmClose(ref.watch(monthRepositoryProvider)),
);

final Provider<ExportBackup> exportBackupProvider = Provider(
  (ref) => ExportBackup(
    ref.watch(monthRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

final Provider<BackupFiles> backupFilesProvider = Provider(
  (ref) => const PickerBackupFiles(),
);

final Provider<ImportBackup> importBackupProvider = Provider(
  (ref) => ImportBackup(
    ref.watch(monthRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

final Provider<ThemeModeStore> themeModeStoreProvider = Provider(
  (ref) => throw UnimplementedError('Provide the theme store at startup'),
);

final NotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    NotifierProvider(ThemeModeNotifier.new);

final class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(themeModeStoreProvider).read();

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(themeModeStoreProvider).write(mode);
  }
}
