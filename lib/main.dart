import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_actions.dart';
import 'package:gemify/data/drift_month_repository.dart';
import 'package:gemify/data/gemify_database.dart';
import 'package:gemify/presentation/app.dart';
import 'package:gemify/presentation/providers.dart';
import 'package:gemify/presentation/theme/theme_preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = GemifyDatabase(driftDatabase(name: 'gemify'));
  final repository = DriftMonthRepository(database, clock: systemClock);
  await StartMonth(repository, systemClock)();
  final themeModeStore = await PreferencesThemeModeStore.open();
  runApp(
    ProviderScope(
      overrides: [
        monthRepositoryProvider.overrideWithValue(repository),
        themeModeStoreProvider.overrideWithValue(themeModeStore),
      ],
      child: const GemifyApp(),
    ),
  );
}
