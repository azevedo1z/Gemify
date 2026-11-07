import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gemify/application/rejections.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/providers.dart';
import 'package:gemify/presentation/shared/failure.dart';
import 'package:gemify/presentation/shared/money_field.dart';
import 'package:gemify/presentation/shared/money_input.dart';

Future<void> editIncome(BuildContext context, {required Money? current}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _IncomeDialog(current: current),
    );

class _IncomeDialog extends ConsumerStatefulWidget {
  const _IncomeDialog({required this.current});

  final Money? current;

  @override
  ConsumerState<_IncomeDialog> createState() => _IncomeDialogState();
}

class _IncomeDialogState extends ConsumerState<_IncomeDialog> {
  late final _controller = TextEditingController(
    text: moneyInputText(widget.current),
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final income = parseMoneyInput(_controller.text);
    if (income == null) {
      setState(() => _error = l10n.incomeRequired);
      return;
    }
    setState(() => _saving = true);
    String? error;
    try {
      await ref.read(setIncomeProvider)(income);
      navigator.pop();
      return;
    } on InvalidIncomeException {
      error = l10n.errorAmountAboveMax;
    } on Exception catch (failure, stack) {
      reportFailure(messenger, l10n.actionFailed, failure, stack);
    }
    if (mounted) {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.incomeTitle),
      content: Card(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: MoneyField(
          controller: _controller,
          label: l10n.amountLabel,
          errorText: _error,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
