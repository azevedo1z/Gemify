import 'package:flutter/material.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/expense_ordering.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_summary.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/action_row.dart';
import 'package:offmoney/presentation/shared/formatters.dart';
import 'package:offmoney/presentation/shared/grouped_section.dart';
import 'package:offmoney/presentation/shared/labels.dart';
import 'package:offmoney/presentation/shared/large_title.dart';
import 'package:offmoney/presentation/theme/metrics.dart';

class MonthView extends StatelessWidget {
  const MonthView({
    required this.month,
    this.onEditIncome,
    this.onAdd,
    this.onEdit,
    this.onClose,
    super.key,
  });

  final Month month;
  final VoidCallback? onEditIncome;
  final ValueChanged<ExpenseCategory>? onAdd;
  final ValueChanged<ExpenseEntry>? onEdit;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = month.summary;
    final sorted = ExpenseOrdering.sorted(month.entries);
    final onAdd = this.onAdd;
    final onClose = this.onClose;
    final totalStyle = theme.textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.only(
        bottom: Metrics.floatingButtonClearance,
      ),
      children: [
        LargeTitle(text: formatReference(month.reference, l10n)),
        GroupedSection(
          children: [_IncomeTile(income: month.income, onTap: onEditIncome)],
        ),
        for (final category in ExpenseCategory.values)
          GroupedSection(
            header: _SectionHeader(
              title: categoryTitle(category, l10n),
              subtotal: categoryTotal(summary, category),
              onAdd: onAdd == null ? null : () => onAdd(category),
            ),
            children: _rowsOf(sorted, category),
          ),
        GroupedSection(
          children: [
            ListTile(
              title: Text(l10n.totalExpenses, style: totalStyle),
              trailing: Text(
                formatMoney(summary.totalExpenses),
                style: totalStyle,
              ),
            ),
          ],
        ),
        if (onClose != null)
          GroupedSection(
            children: [ActionRow(label: l10n.closeMonth, onTap: onClose)],
          ),
      ],
    );
  }

  List<Widget> _rowsOf(List<ExpenseEntry> sorted, ExpenseCategory category) {
    final onEdit = this.onEdit;
    return [
      for (final entry in sorted)
        if (entry.expense.category == category)
          ExpenseTile(
            expense: entry.expense,
            onTap: onEdit == null ? null : () => onEdit(entry),
          ),
    ];
  }
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({required this.expense, this.onTap, super.key});

  final Expense expense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = switch (expense) {
      FixedExpense() => null,
      final InstallmentExpense installment =>
        installment.isLast
            ? l10n.installmentCounterFinal(
                installmentCounter(installment),
                l10n.finalInstallment,
              )
            : installmentCounter(installment),
      VariableExpense(:final spentOn) =>
        spentOn == null ? null : formatDate(spentOn),
    };
    return ListTile(
      title: Text(expense.name),
      subtitle: details == null ? null : Text(details),
      trailing: Text(formatMoney(expense.amount)),
      onTap: onTap,
    );
  }
}

class AuditBar extends StatelessWidget {
  const AuditBar({required this.summary, super.key});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final balance = summary.balance;
    final negative = balance != null && balance.isNegative;
    final labelColor = negative ? scheme.error : scheme.onSurfaceVariant;
    return Material(
      color: theme.bottomAppBarTheme.color,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(Metrics.inset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (negative) ...[
                        Icon(
                          Icons.warning_amber_rounded,
                          color: scheme.error,
                          semanticLabel: l10n.negativeBalance,
                        ),
                        const SizedBox(width: Metrics.headerGap),
                      ],
                      Expanded(
                        child: Text(
                          l10n.balanceTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: labelColor,
                          ),
                        ),
                      ),
                      if (balance == null)
                        Text(
                          l10n.incomePending,
                          key: const Key('balance'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Text(
                          formatMoney(balance),
                          key: const Key('balance'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: negative ? scheme.error : scheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                  if (balance != null)
                    Text(
                      formatAuditLine(summary),
                      key: const Key('auditLine'),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeTile extends StatelessWidget {
  const _IncomeTile({required this.income, required this.onTap});

  final Money? income;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final income = this.income;
    return ListTile(
      title: Text(l10n.incomeTitle),
      trailing: income == null ? null : Text(formatMoney(income)),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtotal,
    required this.onAdd,
  });

  final String title;
  final Money subtotal;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final onAdd = this.onAdd;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
              if (onAdd != null)
                IconButton(
                  tooltip: l10n.addTo(title),
                  onPressed: onAdd,
                  visualDensity: VisualDensity.compact,
                  color: scheme.primary,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
            ],
          ),
        ),
        Text(
          formatMoney(subtotal),
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
