import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offmoney/application/month_actions.dart';
import 'package:offmoney/application/month_repository.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_closing.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/providers.dart';
import 'package:offmoney/presentation/shared/failure.dart';
import 'package:offmoney/presentation/shared/formatters.dart';
import 'package:offmoney/presentation/shared/grouped_section.dart';
import 'package:offmoney/presentation/shared/labels.dart';
import 'package:offmoney/presentation/shared/money_field.dart';
import 'package:offmoney/presentation/shared/money_input.dart';
import 'package:offmoney/presentation/shared/navigation.dart';
import 'package:offmoney/presentation/shared/reference_picker.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

class CloseMonthScreen extends ConsumerStatefulWidget {
  const CloseMonthScreen({super.key});

  @override
  ConsumerState<CloseMonthScreen> createState() => _CloseMonthScreenState();
}

class _CloseMonthScreenState extends ConsumerState<CloseMonthScreen> {
  final _income = TextEditingController();
  ReferenceMonth? _newReference;
  Month? _closingMonth;

  static const Set<CloseError> _blockingErrors = {
    CloseError.monthNotOpen,
    CloseError.incomeMissing,
    CloseError.invalidExpenses,
  };

  bool get _closing => _closingMonth != null;

  @override
  void dispose() {
    _income.dispose();
    super.dispose();
  }

  CloseOutcome _outcome(PrepareClose prepare, Month month) => prepare(
    month,
    newReference: _newReference,
    newIncome: parseMoneyInput(_income.text),
  );

  Future<void> _pickReference(Month month) async {
    final l10n = AppLocalizations.of(context);
    final picked = await pickReference(
      context,
      title: l10n.nextReference,
      confirmLabel: l10n.choose,
      initial: _newReference ?? month.reference.next(),
      window: ref.read(prepareCloseProvider).window(month),
    );
    if (picked != null && mounted) setState(() => _newReference = picked);
  }

  Future<void> _confirm(Month month) async {
    final plan = switch (_outcome(ref.read(prepareCloseProvider), month)) {
      ClosePlanned(:final plan) => plan,
      CloseRejected() => null,
    };
    if (plan == null || _closing) return;
    setState(() => _closingMonth = month);
    final closed = await _monthClosed(plan);
    if (!mounted) return;
    if (closed) {
      popIfCurrent(context);
    } else {
      setState(() => _closingMonth = null);
    }
  }

  Future<bool> _monthClosed(ClosePlan plan) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(confirmCloseProvider).call(plan);
      return true;
    } on CloseConflictException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.closeConflict)));
      return true;
    } on Exception catch (error, stack) {
      reportFailure(messenger, l10n.actionFailed, error, stack);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final watched = ref.watch(openMonthProvider).valueOrNull;
    final prepare = ref.watch(prepareCloseProvider);
    final month = _closingMonth ?? watched;
    return PopScope(
      canPop: !_closing,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            month == null
                ? l10n.closeMonth
                : l10n.closeTitle(formatReference(month.reference, l10n)),
          ),
        ),
        body: month == null
            ? const Center(child: CircularProgressIndicator())
            : switch (_outcome(prepare, month)) {
                final CloseRejected rejection
                    when rejection.errors.any(_blockingErrors.contains) =>
                  _blocked(month, rejection, l10n),
                final outcome => _form(month, outcome, l10n),
              },
      ),
    );
  }

  Widget _blocked(
    Month month,
    CloseRejected rejection,
    AppLocalizations l10n,
  ) {
    final problemIcon = Icon(
      Icons.error_outline_rounded,
      color: Theme.of(context).colorScheme.error,
    );
    return ListView(
      padding: const EdgeInsets.only(top: Metrics.inset),
      children: [
        GroupedSection(
          children: [
            if (rejection.errors.contains(CloseError.incomeMissing))
              ListTile(leading: problemIcon, title: Text(l10n.incomeRequired)),
            for (final entry in month.entries)
              if (rejection.invalidEntries[entry.id] case final errors?)
                ListTile(
                  leading: problemIcon,
                  title: Text(entry.expense.name),
                  subtitle: Text(
                    [
                      for (final error in errors)
                        expenseErrorMessage(error, l10n),
                    ].join(' · '),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _form(Month month, CloseOutcome outcome, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final plan = switch (outcome) {
      ClosePlanned(:final plan) => plan,
      CloseRejected() => null,
    };
    final errors = switch (outcome) {
      CloseRejected(:final errors) => errors,
      ClosePlanned() => const <CloseError>{},
    };
    final newReference = _newReference ?? month.reference.next();
    final keptIncome = month.income ?? Money.zero;
    return ListView(
      padding: const EdgeInsets.only(top: Metrics.inset),
      children: [
        GroupedSection(
          header: Text(l10n.closeNewMonth),
          footer: plan == null
              ? null
              : Text(
                  plan.incomeKept
                      ? l10n.closeIncomeKept(formatMoney(plan.newIncome))
                      : l10n.closeIncomeInformed(formatMoney(plan.newIncome)),
                  key: const Key('newIncomeLine'),
                ),
          children: [
            ListTile(
              enabled: !_closing,
              title: Text(l10n.referenceLabel),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatReference(newReference, l10n),
                    style: TextStyle(color: scheme.primary),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              onTap: () => _pickReference(month),
            ),
            MoneyField(
              controller: _income,
              label: l10n.closeNewIncome,
              hint: formatMoney(keptIncome),
              errorText: errors.contains(CloseError.newIncomeOutOfRange)
                  ? l10n.errorAmountAboveMax
                  : null,
              enabled: !_closing,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        if (plan != null) ..._preview(month, plan, l10n),
      ],
    );
  }

  List<Widget> _preview(Month month, ClosePlan plan, AppLocalizations l10n) {
    final summary = plan.closingSummary;
    return [
      GroupedSection(
        children: [
          _line(
            l10n.closeVariablesCleared,
            l10n.countAndTotal(
              l10n.itemCount(plan.clearedVariables.length),
              formatMoney(summary.variableTotal),
            ),
          ),
          _line(
            l10n.closeFixedKept,
            l10n.countAndTotal(
              l10n.itemCount(plan.keptFixed.length),
              formatMoney(summary.fixedTotal),
            ),
          ),
        ],
      ),
      if (plan.advancing.isNotEmpty)
        GroupedSection(
          header: Text(l10n.closeInstallmentsAdvancing),
          children: [
            for (final step in plan.advancing)
              _line(
                step.from.name,
                l10n.closeInstallmentStep(
                  installmentCounter(step.from),
                  installmentCounter(step.to),
                ),
              ),
          ],
        ),
      if (plan.finishing.isNotEmpty)
        GroupedSection(
          header: Text(l10n.closeInstallmentsFinishing),
          children: [
            for (final installment in plan.finishing)
              _line(installment.name, installmentCounter(installment)),
          ],
        ),
      GroupedSection(
        children: [
          _line(
            l10n.closeClosingBalance,
            formatMoney(summary.balance ?? Money.zero),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Metrics.inset,
          0,
          Metrics.inset,
          Metrics.sectionGap,
        ),
        child: FilledButton(
          onPressed: _closing ? null : () => _confirm(month),
          child: Text(l10n.closeMonth),
        ),
      ),
    ];
  }

  Widget _line(String title, String value) =>
      ListTile(title: Text(title), trailing: Text(value));
}
