import 'package:flutter/material.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';

Future<ThemeMode?> pickThemeMode(
  BuildContext context, {
  required ThemeMode initial,
}) => showDialog<ThemeMode>(
  context: context,
  builder: (dialogContext) {
    final l10n = AppLocalizations.of(dialogContext);
    return SimpleDialog(
      title: Text(l10n.theme),
      children: [
        RadioGroup<ThemeMode>(
          groupValue: initial,
          onChanged: (mode) => Navigator.of(dialogContext).pop(mode),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in ThemeMode.values)
                RadioListTile<ThemeMode>(
                  value: mode,
                  title: Text(_label(mode, l10n)),
                ),
            ],
          ),
        ),
      ],
    );
  },
);

String _label(ThemeMode mode, AppLocalizations l10n) => switch (mode) {
  ThemeMode.system => l10n.themeSystem,
  ThemeMode.light => l10n.themeLight,
  ThemeMode.dark => l10n.themeDark,
};
