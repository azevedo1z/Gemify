import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/rejections.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/presentation/backup/backup_actions.dart';
import 'package:offmoney/presentation/close_month/close_month_screen.dart';
import 'package:offmoney/presentation/expense_form/expense_form_screen.dart';
import 'package:offmoney/presentation/history/history_screen.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/month/category_picker.dart';
import 'package:offmoney/presentation/month/income_dialog.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/shared/month_view.dart';
import 'package:offmoney/presentation/shared/reference_picker.dart';
import 'package:offmoney/presentation/shared/share_text.dart';
import 'package:offmoney/presentation/theme/theme_picker.dart';
import 'package:share_plus/share_plus.dart';

class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(openMonthProvider)) {
        AsyncData(:final value) => _OpenMonthPage(month: value),
        AsyncError() => Scaffold(
          body: Center(child: Text(AppLocalizations.of(context).loadFailed)),
        ),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      };
}

enum _MenuAction { changeReference, exportBackup, importBackup, theme, about }

class _OpenMonthPage extends ConsumerWidget {
  const _OpenMonthPage({required this.month});

  final Month month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.history,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
            ),
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: l10n.share,
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: shareText(month, l10n)),
            ),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          PopupMenuButton<_MenuAction>(
            icon: const Icon(Icons.more_horiz_rounded),
            onSelected: (action) => switch (action) {
              _MenuAction.changeReference => _changeReference(context, ref),
              _MenuAction.exportBackup => exportBackup(context, ref),
              _MenuAction.importBackup => importBackup(context, ref),
              _MenuAction.theme => _pickTheme(context, ref),
              _MenuAction.about => showAboutDialog(
                context: context,
                applicationName: l10n.appTitle,
                applicationLegalese: l10n.aboutDisclaimer,
              ),
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _MenuAction.changeReference,
                child: Text(l10n.changeReference),
              ),
              PopupMenuItem(
                value: _MenuAction.exportBackup,
                child: Text(l10n.exportBackup),
              ),
              PopupMenuItem(
                value: _MenuAction.importBackup,
                child: Text(l10n.importBackup),
              ),
              PopupMenuItem(
                value: _MenuAction.theme,
                child: Text(l10n.theme),
              ),
              PopupMenuItem(
                value: _MenuAction.about,
                child: Text(l10n.about),
              ),
            ],
          ),
        ],
      ),
      body: MonthView(
        month: month,
        onEditIncome: () => editIncome(context, current: month.income),
        onAdd: (category) => openExpenseForm(context, category),
        onEdit: (entry) =>
            openExpenseForm(context, entry.expense.category, entry: entry),
        onClose: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CloseMonthScreen()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.newExpense,
        onPressed: () => _addExpense(context),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: AuditBar(summary: month.summary),
    );
  }

  Future<void> _addExpense(BuildContext context) async {
    final category = await pickExpenseCategory(context);
    if (category == null || !context.mounted) return;
    await openExpenseForm(context, category);
  }

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final picked = await pickThemeMode(
      context,
      initial: ref.read(themeModeProvider),
    );
    if (picked == null) return;
    await ref.read(themeModeProvider.notifier).select(picked);
  }

  Future<void> _changeReference(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final changeReference = ref.read(changeOpenReferenceProvider);
    final window = await changeReference.window();
    if (!context.mounted) return;
    final picked = await pickReference(
      context,
      title: l10n.changeReference,
      confirmLabel: l10n.save,
      initial: month.reference,
      window: window,
    );
    if (picked == null || picked == month.reference) return;
    try {
      await changeReference(picked);
    } on InvalidReferenceException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.referenceUnavailable)),
      );
    }
  }
}
