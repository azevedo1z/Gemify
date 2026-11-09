import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/rejections.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/shared/failure.dart';
import 'package:offmoney/presentation/shared/money_field.dart';
import 'package:offmoney/presentation/shared/money_input.dart';
import 'package:offmoney/presentation/shared/navigation.dart';

Future<void> editIncome(BuildContext context, {required Money? current}) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
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
    final income = parseMoneyInput(_controller.text);
    if (income == null) {
      setState(() => _error = l10n.incomeRequired);
      return;
    }
    setState(() => _saving = true);
    String? error;
    var saved = false;
    try {
      await ref.read(setIncomeProvider)(income);
      saved = true;
    } on InvalidIncomeException {
      error = l10n.errorAmountAboveMax;
    } on Exception catch (failure, stack) {
      reportFailure(messenger, l10n.actionFailed, failure, stack);
    } finally {
      if (!saved && mounted) {
        setState(() {
          _saving = false;
          _error = error;
        });
      }
    }
    if (!saved || !mounted) return;
    popIfCurrent(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(l10n.incomeTitle),
        content: Card(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: MoneyField(
            controller: _controller,
            errorText: _error,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}
