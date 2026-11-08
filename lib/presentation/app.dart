import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/month/month_screen.dart';
import 'package:gemify/presentation/providers.dart';
import 'package:gemify/presentation/theme/app_theme.dart';

class GemifyApp extends ConsumerWidget {
  const GemifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MonthScreen(),
    );
  }
}
