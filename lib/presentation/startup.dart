import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/clock.dart';
import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/application/month_repository.dart';
import 'package:offmoney/presentation/app.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/theme/app_theme.dart';
import 'package:offmoney/presentation/theme/theme_preference.dart';

Future<Widget> startApp({
  required MonthRepository Function() openRepository,
  required Future<ThemeModeStore> Function() openThemeModeStore,
  required Clock clock,
}) async {
  try {
    final repository = openRepository();
    await StartMonth(repository, clock)();
    final themeModeStore = await openThemeModeStore();
    return ProviderScope(
      overrides: [
        monthRepositoryProvider.overrideWithValue(repository),
        themeModeStoreProvider.overrideWithValue(themeModeStore),
        clockProvider.overrideWithValue(clock),
      ],
      child: const OffMoneyApp(),
    );
  } on Object catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'offmoney'),
    );
    return const StartupFailedApp();
  }
}

class StartupFailedApp extends StatelessWidget {
  const StartupFailedApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: Text(
            AppLocalizations.of(context).startupFailed,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
