import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/names.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/shared/action_row.dart';
import 'package:offmoney/presentation/shared/confirm_dialog.dart';
import 'package:offmoney/presentation/shared/failure.dart';
import 'package:offmoney/presentation/shared/formatters.dart';
import 'package:offmoney/presentation/shared/grouped_section.dart';
import 'package:offmoney/presentation/shared/labels.dart';
import 'package:offmoney/presentation/shared/money_field.dart';
import 'package:offmoney/presentation/shared/money_input.dart';
import 'package:offmoney/presentation/shared/navigation.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

Future<void> openExpenseForm(
  BuildContext context,
  ExpenseCategory category, {
  ExpenseEntry? entry,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ExpenseFormScreen(category: category, entry: entry),
  ),
);

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({required this.category, this.entry, super.key});

  final ExpenseCategory category;
  final ExpenseEntry? entry;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  static const _maxCounterDigits = 3;
  static const _maxSuggestions = 5;
  static const _firstSelectableYear = 2000;
  static const _suggestionsHeight = 240.0;

  late final _name = TextEditingController(text: widget.entry?.expense.name);
  late final _amount = TextEditingController(
    text: moneyInputText(widget.entry?.expense.amount),
  );
  late final _current = TextEditingController(
    text: _installment?.current.toString(),
  );
  late final _total = TextEditingController(
    text: _installment?.total.toString(),
  );
  final _nameFocus = FocusNode();
  late CalendarDate _spentOn = _existingDate ?? ref.read(todayProvider).call();
  Set<ExpenseError> _errors = const {};
  bool _currentMissing = false;
  bool _totalMissing = false;
  bool _busy = false;

  InstallmentExpense? get _installment => switch (widget.entry?.expense) {
    final InstallmentExpense installment => installment,
    _ => null,
  };

  CalendarDate? get _existingDate => switch (widget.entry?.expense) {
    VariableExpense(:final spentOn) => spentOn,
    _ => null,
  };

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _current.dispose();
    _total.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _isInstallment => widget.category == ExpenseCategory.installment;

  Expense? _buildExpense(int? current, int? total) {
    final name = _name.text;
    final amount = parseMoneyInput(_amount.text) ?? Money.zero;
    return switch (widget.category) {
      ExpenseCategory.fixed => FixedExpense(name: name, amount: amount),
      ExpenseCategory.variable => VariableExpense(
        name: name,
        amount: amount,
        spentOn: _spentOn,
      ),
      ExpenseCategory.installment when current != null && total != null =>
        InstallmentExpense(
          name: name,
          amount: amount,
          current: current,
          total: total,
        ),
      ExpenseCategory.installment => null,
    };
  }

  Future<void> _save() async {
    if (_busy) return;
    final current = int.tryParse(_current.text);
    final total = int.tryParse(_total.text);
    setState(() {
      _currentMissing = _isInstallment && current == null;
      _totalMissing = _isInstallment && total == null;
    });
    final built = _buildExpense(current, total);
    if (built == null) return;
    await _run(() async {
      final check = await ref
          .read(checkExpenseProvider)
          .call(built, original: widget.entry);
      if (!mounted) return false;
      setState(() => _errors = check.errors);
      if (!check.isValid) return false;
      if (check.warnings.isNotEmpty && !await _confirm(check)) return false;
      await ref
          .read(saveExpenseProvider)
          .call(check.expense, replacingId: widget.entry?.id);
      return true;
    });
  }

  Future<void> _run(Future<bool> Function() action) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    var done = false;
    try {
      done = await action();
    } on Exception catch (error, stack) {
      reportFailure(messenger, l10n.actionFailed, error, stack);
    } finally {
      if (!done && mounted) setState(() => _busy = false);
    }
    if (!done || !mounted) return;
    popIfCurrent(context);
  }

  Future<bool> _confirm(ExpenseCheck check) {
    final l10n = AppLocalizations.of(context);
    return showConfirmDialog(
      context,
      title: l10n.warningTitle,
      action: l10n.save,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final warning in check.warnings)
            Text(switch (warning) {
              ExpenseWarning.exceedsBalance => l10n.warningExceedsBalance(
                formatMoney(check.addedAmount),
                formatMoney(check.balance ?? Money.zero),
              ),
              ExpenseWarning.possibleDuplicate => l10n.warningPossibleDuplicate,
            }),
        ],
      ),
    );
  }

  Future<void> _delete(ExpenseEntry entry) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteTitle,
      action: l10n.delete,
      destructive: true,
      content: Text(
        l10n.deleteMessage(
          entry.expense.name,
          formatMoney(entry.expense.amount),
        ),
      ),
    );
    if (!confirmed || !mounted) return;
    await _run(() async {
      await ref.read(deleteExpenseProvider).call(entry.id);
      return true;
    });
  }

  Future<void> _pickDate() async {
    final today = ref.read(todayProvider).call();
    final current = DateTime(_spentOn.year, _spentOn.month, _spentOn.day);
    final latest = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(math.min(_firstSelectableYear, _spentOn.year)),
      lastDate: current.isAfter(latest) ? current : latest,
    );
    if (picked != null) setState(() => _spentOn = CalendarDate.of(picked));
  }

  String? _errorText(Set<ExpenseError> relevant, AppLocalizations l10n) {
    final error = _errors.where(relevant.contains).firstOrNull;
    return error == null ? null : expenseErrorMessage(error, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final dateError = _errorText({
      ExpenseError.dateMissing,
      ExpenseError.dateInFuture,
    }, l10n);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title(l10n)),
          actions: [
            TextButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: Metrics.inset),
          children: [
            GroupedSection(
              children: [
                _nameField(l10n),
                MoneyField(
                  controller: _amount,
                  label: _isInstallment
                      ? l10n.installmentAmountLabel
                      : l10n.amountLabel,
                  errorText: _errorText({
                    ExpenseError.amountNotPositive,
                    ExpenseError.amountAboveMax,
                  }, l10n),
                ),
                if (widget.category == ExpenseCategory.variable)
                  ListTile(
                    title: Text(l10n.dateLabel),
                    trailing: Text(
                      dateError ?? formatDate(_spentOn),
                      style: TextStyle(
                        color: dateError == null
                            ? scheme.primary
                            : scheme.error,
                      ),
                    ),
                    onTap: _pickDate,
                  ),
                if (_isInstallment) ..._counterFields(l10n),
              ],
            ),
            if (entry != null)
              GroupedSection(
                children: [
                  ActionRow(
                    label: l10n.delete,
                    destructive: true,
                    onTap: () => _delete(entry),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _nameField(AppLocalizations l10n) {
    final names =
        ref.watch(usedNamesProvider(widget.category)).valueOrNull ?? [];
    return RawAutocomplete<String>(
      textEditingController: _name,
      focusNode: _nameFocus,
      optionsBuilder: (value) {
        final key = Names.key(value.text);
        if (key.isEmpty) return const [];
        return names
            .where((name) {
              final candidate = Names.key(name);
              return candidate != key && candidate.contains(key);
            })
            .take(_maxSuggestions);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.nameLabel,
              errorText: _errorText({
                ExpenseError.nameEmpty,
                ExpenseError.nameTooLong,
              }, l10n),
            ),
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Theme.of(context).cardTheme.color,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(
              Radius.circular(Metrics.radius),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: Metrics.hairline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _suggestionsHeight),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _counterFields(AppLocalizations l10n) {
    final rangeError = _errorText({
      ExpenseError.installmentCurrentOutOfRange,
    }, l10n);
    final totalError = _errorText({
      ExpenseError.installmentTotalBelowMinimum,
    }, l10n);
    return [
      _counterField(
        _current,
        l10n.currentInstallmentLabel,
        _currentMissing ? l10n.errorNumberRequired : rangeError,
      ),
      _counterField(
        _total,
        l10n.totalInstallmentsLabel,
        _totalMissing ? l10n.errorNumberRequired : totalError,
      ),
    ];
  }

  Widget _counterField(
    TextEditingController controller,
    String label,
    String? error,
  ) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(_maxCounterDigits),
    ],
    decoration: InputDecoration(labelText: label, errorText: error),
  );

  String _title(AppLocalizations l10n) {
    final editing = widget.entry != null;
    return switch (widget.category) {
      ExpenseCategory.fixed => editing ? l10n.editFixed : l10n.newFixed,
      ExpenseCategory.installment =>
        editing ? l10n.editInstallment : l10n.newInstallment,
      ExpenseCategory.variable =>
        editing ? l10n.editVariable : l10n.newVariable,
    };
  }
}
