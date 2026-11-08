import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gemify/application/clock.dart';
import 'package:gemify/data/drift_month_repository.dart';
import 'package:gemify/data/gemify_database.dart';
import 'package:gemify/presentation/startup.dart';
import 'package:gemify/presentation/theme/theme_preference.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    await startApp(
      openRepository: () => DriftMonthRepository(
        GemifyDatabase(driftDatabase(name: 'gemify')),
        clock: systemClock,
      ),
      openThemeModeStore: PreferencesThemeModeStore.open,
      clock: systemClock,
    ),
  );
}
