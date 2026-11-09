import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/presentation/startup.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/app_seeds.dart';
import '../support/fake_theme_mode_store.dart';
import '../support/memory_repository.dart';

const startupFailed = 'Não foi possível abrir os dados. Feche e abra o app.';

Future<FakeThemeModeStore> openThemeModeStore() async =>
    FakeThemeModeStore(ThemeMode.system);

void main() {
  testWidgets('opens the app on the open month', (tester) async {
    final memory = (await tester.runAsync(MemoryRepository.open))!;
    addTearDown(() => tester.runAsync(memory.close));

    final app = (await tester.runAsync(
      () => startApp(
        openRepository: () => memory.repository,
        openThemeModeStore: openThemeModeStore,
        clock: memory.clock.call,
      ),
    ))!;
    await tester.pumpWidget(app);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('nov/2026'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('shows an error screen when the database cannot open', (
    tester,
  ) async {
    final app = await startApp(
      openRepository: () => throw const FileSystemException('locked'),
      openThemeModeStore: openThemeModeStore,
      clock: TestClock().call,
    );
    expect(tester.takeException(), isA<FileSystemException>());

    await tester.pumpWidget(app);

    expect(find.text(startupFailed), findsOneWidget);
  });

  testWidgets('shows an error screen when the month cannot start', (
    tester,
  ) async {
    final memory = (await tester.runAsync(MemoryRepository.open))!;
    addTearDown(() => tester.runAsync(memory.close));
    await tester.runAsync(() async {
      await memory.database.delete(memory.database.months).go();
      await failingOn('months')(memory);
    });

    final app = (await tester.runAsync(
      () => startApp(
        openRepository: () => memory.repository,
        openThemeModeStore: openThemeModeStore,
        clock: memory.clock.call,
      ),
    ))!;
    expect(tester.takeException(), isA<SqliteException>());
    await tester.pumpWidget(app);

    expect(find.text(startupFailed), findsOneWidget);
  });
}
