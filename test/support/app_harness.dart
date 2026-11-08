import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/presentation/app.dart';
import 'package:gemify/presentation/providers.dart';

import 'fake_backup_files.dart';
import 'fake_theme_mode_store.dart';
import 'memory_repository.dart';

typedef Seed = Future<void> Function(MemoryRepository memory);

void testApp(
  String description,
  Future<void> Function(AppHarness app) body, {
  Seed? seed,
  ThemeMode themeMode = ThemeMode.system,
}) {
  testWidgets(description, (tester) async {
    final app = await AppHarness._start(tester, seed, themeMode);
    try {
      await body(app);
    } finally {
      await app._stop();
    }
  });
}

final class AppHarness {
  AppHarness._(this.tester, this.memory, ThemeMode themeMode)
    : themeModeStore = FakeThemeModeStore(themeMode);

  static const phoneSize = Size(1080, 2400);
  static const phonePixelRatio = 3.0;

  static const _step = Duration(milliseconds: 1);
  static const _maxSteps = 1000;

  static Future<AppHarness> _start(
    WidgetTester tester,
    Seed? seed,
    ThemeMode themeMode,
  ) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final memory = await _drive(tester, MemoryRepository.open());
    if (seed != null) await _drive(tester, seed(memory));
    final harness = AppHarness._(tester, memory, themeMode);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          monthRepositoryProvider.overrideWithValue(memory.repository),
          clockProvider.overrideWithValue(memory.clock.call),
          backupFilesProvider.overrideWithValue(harness.files),
          themeModeStoreProvider.overrideWithValue(harness.themeModeStore),
        ],
        child: const GemifyApp(),
      ),
    );
    await harness.settle();
    return harness;
  }

  static Future<T> _drive<T>(WidgetTester tester, Future<T> future) async {
    late T value;
    (Object, StackTrace)? failure;
    var done = false;
    future
        .then(
          (result) {
            value = result;
            done = true;
          },
          onError: (Object error, StackTrace stack) {
            failure = (error, stack);
            done = true;
          },
        )
        .ignore();
    for (var step = 0; step < _maxSteps && !done; step++) {
      await tester.pump(_step);
    }
    if (!done) fail('The future did not complete');
    if (failure case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
    return value;
  }

  final WidgetTester tester;
  final MemoryRepository memory;
  final FakeBackupFiles files = FakeBackupFiles();
  final FakeThemeModeStore themeModeStore;

  Future<void> settle() => tester.pumpAndSettle();

  Future<T> wait<T>(Future<T> future) => _drive(tester, future);

  Future<void> tap(Finder finder) async {
    await tester.tap(finder);
    await settle();
  }

  Future<void> enter(Finder field, String text) async {
    await tester.enterText(field, text);
    await settle();
  }

  Future<void> backspace(Finder field) async {
    final text = tester.widget<TextField>(field).controller?.text ?? '';
    await enter(field, text.substring(0, text.length - 1));
  }

  Future<void> usePhoneScreen() async {
    tester.view
      ..physicalSize = phoneSize
      ..devicePixelRatio = phonePixelRatio;
    await settle();
  }

  Future<void> _stop() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(_step);
    await _drive(tester, memory.close());
  }
}
