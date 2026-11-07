import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemify/application/backup/backup_codec.dart';
import 'package:gemify/application/backup/backup_snapshot.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/providers.dart';
import 'package:gemify/presentation/shared/confirm_dialog.dart';
import 'package:gemify/presentation/shared/failure.dart';
import 'package:gemify/presentation/shared/formatters.dart';

Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final export = ref.read(exportBackupProvider);
  try {
    final saved = await ref
        .read(backupFilesProvider)
        .save(export.fileName(), await export());
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupSaved)));
    }
  } on Exception catch (error, stack) {
    reportFailure(messenger, l10n.backupSaveFailed, error, stack);
  }
}

Future<void> importBackup(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final String? text;
  try {
    text = await ref.read(backupFilesProvider).open();
  } on Exception catch (error, stack) {
    reportFailure(messenger, l10n.importReadFailed, error, stack);
    return;
  }
  if (text == null) return;
  final import = ref.read(importBackupProvider);
  switch (import.read(text)) {
    case BackupRejected(:final problem):
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importInvalid(_reason(problem, l10n)))),
      );
    case BackupAccepted(:final snapshot):
      if (!context.mounted || !await _confirmReplace(context, snapshot)) {
        return;
      }
      try {
        await import.apply(snapshot);
        messenger.showSnackBar(SnackBar(content: Text(l10n.importDone)));
      } on Exception catch (error, stack) {
        reportFailure(messenger, l10n.importFailed, error, stack);
      }
  }
}

Future<bool> _confirmReplace(BuildContext context, BackupSnapshot snapshot) {
  final l10n = AppLocalizations.of(context);
  final open = snapshot.months.firstWhere((month) => month.isOpen);
  return showConfirmDialog(
    context,
    title: l10n.importConfirmTitle,
    action: l10n.replace,
    destructive: true,
    content: Text(
      l10n.importConfirmMessage(
        l10n.monthCount(snapshot.months.length),
        formatReference(open.reference, l10n),
      ),
    ),
  );
}

String _reason(BackupProblem problem, AppLocalizations l10n) =>
    switch (problem) {
      BackupProblem.notGemifyBackup => l10n.importReasonFormat,
      BackupProblem.unknownVersion => l10n.importReasonVersion,
      BackupProblem.invalidStructure => l10n.importReasonStructure,
      BackupProblem.invalidTimeline => l10n.importReasonTimeline,
      BackupProblem.invalidExpenses => l10n.importReasonExpenses,
      BackupProblem.invalidChangeLog => l10n.importReasonChangeLog,
    };
