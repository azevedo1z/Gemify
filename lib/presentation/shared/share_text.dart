import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_ordering.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';
import 'package:gemify/presentation/shared/formatters.dart';
import 'package:gemify/presentation/shared/labels.dart';

String shareText(Month month, AppLocalizations l10n) {
  final summary = month.summary;
  final income = summary.income;
  final sorted = ExpenseOrdering.sorted(month.entries);
  final buffer = StringBuffer()
    ..writeln(l10n.shareHeading(formatReference(month.reference, l10n)))
    ..writeln()
    ..writeln('1. ${l10n.incomeTitle}')
    ..writeln(
      income == null
          ? l10n.incomePending
          : l10n.shareIncomeLine(formatMoney(income)),
    );
  for (final (index, category) in ExpenseCategory.values.indexed) {
    final expenses = [
      for (final entry in sorted)
        if (entry.expense.category == category) entry.expense,
    ];
    buffer
      ..writeln()
      ..writeln('${index + 2}. ${categoryTitle(category, l10n)}');
    if (expenses.isEmpty) buffer.writeln(l10n.noExpenses);
    for (final expense in expenses) {
      buffer.writeln(
        '- ${expense.name}${_details(expense, l10n)}: '
        '${formatMoney(expense.amount)}',
      );
    }
    buffer.writeln(
      _totalLine(category, formatMoney(categoryTotal(summary, category)), l10n),
    );
  }
  buffer
    ..writeln()
    ..writeln(l10n.shareAuditHeading)
    ..writeln(l10n.auditFormula)
    ..write(income == null ? l10n.incomePending : formatAuditLine(summary));
  return buffer.toString();
}

String _details(Expense expense, AppLocalizations l10n) => switch (expense) {
  final InstallmentExpense installment when installment.isLast =>
    ' (${installmentCounter(installment)}, ${l10n.finalInstallment})',
  final InstallmentExpense installment =>
    ' (${installmentCounter(installment)})',
  FixedExpense() || VariableExpense() => '',
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
