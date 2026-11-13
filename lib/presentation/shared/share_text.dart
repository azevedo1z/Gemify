import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_ordering.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/formatters.dart';
import 'package:offmoney/presentation/shared/labels.dart';

const _incomeSection = 1;

String shareText(Month month, AppLocalizations l10n) {
  final summary = month.summary;
  final income = summary.income;
  final sorted = ExpenseOrdering.sorted(month.entries);
  final buffer = StringBuffer()
    ..writeln(l10n.shareHeading(formatReference(month.reference, l10n)))
    ..writeln()
    ..writeln(l10n.shareSectionTitle(_incomeSection, l10n.incomeTitle))
    ..writeln(
      income == null
          ? l10n.incomePending
          : l10n.shareIncomeLine(formatMoney(income)),
    );
  for (final category in ExpenseCategory.values) {
    final expenses = [
      for (final entry in sorted)
        if (entry.expense.category == category) entry.expense,
    ];
    buffer
      ..writeln()
      ..writeln(
        l10n.shareSectionTitle(
          _sectionOf(category),
          categoryTitle(category, l10n),
        ),
      );
    if (expenses.isEmpty) buffer.writeln(l10n.noExpenses);
    for (final expense in expenses) {
      buffer.writeln(
        l10n.shareExpenseLine(
          _nameOf(expense, l10n),
          formatMoney(expense.amount),
        ),
      );
    }
    buffer.writeln(
      _totalLine(category, formatMoney(summary.totalOf(category)), l10n),
    );
  }
  buffer
    ..writeln()
    ..writeln(l10n.shareAuditHeading)
    ..writeln(l10n.auditFormula)
    ..write(income == null ? l10n.incomePending : formatAuditLine(summary));
  return buffer.toString();
}

int _sectionOf(ExpenseCategory category) => _incomeSection + 1 + category.index;

String _nameOf(Expense expense, AppLocalizations l10n) => switch (expense) {
  final InstallmentExpense installment when installment.isLast =>
    l10n.shareFinalInstallmentName(
      installment.name,
      installmentCounter(installment),
      l10n.finalInstallment,
    ),
  final InstallmentExpense installment => l10n.shareInstallmentName(
    installment.name,
    installmentCounter(installment),
  ),
  FixedExpense() || VariableExpense() => expense.name,
};

String _totalLine(
  ExpenseCategory category,
  String amount,
  AppLocalizations l10n,
) => switch (category) {
  ExpenseCategory.fixed => l10n.shareFixedTotal(amount),
  ExpenseCategory.installment => l10n.shareInstallmentTotal(amount),
  ExpenseCategory.variable => l10n.shareVariableTotal(amount),
};
