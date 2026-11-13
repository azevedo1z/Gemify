import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';

String categoryTitle(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.fixed => l10n.fixedTitle,
      ExpenseCategory.installment => l10n.installmentTitle,
      ExpenseCategory.variable => l10n.variableTitle,
    };

String newExpenseTitle(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.fixed => l10n.newFixed,
      ExpenseCategory.installment => l10n.newInstallment,
      ExpenseCategory.variable => l10n.newVariable,
    };

String editExpenseTitle(ExpenseCategory category, AppLocalizations l10n) =>
    switch (category) {
      ExpenseCategory.fixed => l10n.editFixed,
      ExpenseCategory.installment => l10n.editInstallment,
      ExpenseCategory.variable => l10n.editVariable,
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
      ExpenseError.installmentTotalBelowMinimum =>
        l10n.errorInstallmentTotalBelowMinimum(
          ExpenseRules.minimumInstallments,
        ),
      ExpenseError.installmentCurrentOutOfRange =>
        l10n.errorInstallmentCurrentOutOfRange,
      ExpenseError.dateMissing => l10n.errorDateMissing,
      ExpenseError.dateInFuture => l10n.errorDateInFuture,
    };
