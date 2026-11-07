import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month_summary.dart';
import 'package:gemify/presentation/l10n/generated/app_localizations.dart';

String categoryTitle(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.fixed => l10n.fixedTitle,
      ExpenseCategory.installment => l10n.installmentTitle,
      ExpenseCategory.variable => l10n.variableTitle,
    };

Money categoryTotal(MonthSummary summary, ExpenseCategory category) =>
    switch (category) {
      ExpenseCategory.fixed => summary.fixedTotal,
      ExpenseCategory.installment => summary.installmentTotal,
      ExpenseCategory.variable => summary.variableTotal,
    };

String installmentCounter(InstallmentExpense installment) =>
    '${installment.current}/${installment.total}';

String expenseErrorMessage(ExpenseError error, AppLocalizations l10n) =>
    switch (error) {
      ExpenseError.nameEmpty => l10n.errorNameEmpty,
      ExpenseError.nameTooLong => l10n.errorNameTooLong(
        ExpenseRules.nameMaxLength,
      ),
      ExpenseError.amountNotPositive => l10n.errorAmountNotPositive,
      ExpenseError.amountAboveMax => l10n.errorAmountAboveMax,
      ExpenseError.installmentTotalBelowTwo =>
        l10n.errorInstallmentTotalBelowTwo,
      ExpenseError.installmentCurrentOutOfRange =>
        l10n.errorInstallmentCurrentOutOfRange,
      ExpenseError.dateMissing => l10n.errorDateMissing,
      ExpenseError.dateInFuture => l10n.errorDateInFuture,
    };
