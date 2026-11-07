import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/names.dart';

enum ExpenseError {
  nameEmpty,
  nameTooLong,
  amountNotPositive,
  amountAboveMax,
  installmentTotalBelowTwo,
  installmentCurrentOutOfRange,
  dateMissing,
  dateInFuture,
}

enum ExpenseWarning { exceedsBalance, possibleDuplicate }

abstract final class ExpenseRules {
  static const nameMaxLength = 80;
  static const minimumInstallments = 2;

  static Set<ExpenseError> errors(
    Expense expense, {
    required MonthStatus status,
    required CalendarDate today,
  }) {
    final name = Names.clean(expense.name);
    return {
      if (name.isEmpty) ExpenseError.nameEmpty,
      if (name.runes.length > nameMaxLength) ExpenseError.nameTooLong,
      if (!expense.amount.isPositive) ExpenseError.amountNotPositive,
      if (expense.amount > Money.max) ExpenseError.amountAboveMax,
      ...switch (expense) {
        FixedExpense() => const <ExpenseError>{},
        InstallmentExpense(:final current, :final total) => {
          if (total < minimumInstallments)
            ExpenseError.installmentTotalBelowTwo,
          if (current < 1 || current > total)
            ExpenseError.installmentCurrentOutOfRange,
        },
        VariableExpense(:final spentOn) => _dateErrors(spentOn, status, today),
      },
    };
  }

  static Set<ExpenseWarning> warnings(
    Expense candidate, {
    required Month month,
    ExpenseEntry? original,
  }) {
    final added = addedAmount(candidate, original: original);
    final balance = month.summary.balance;
    final others = month.entries.where((entry) => entry.id != original?.id);
    return {
      if (balance != null && added.isPositive && added > balance)
        ExpenseWarning.exceedsBalance,
      if (others.any((entry) => _looksLike(candidate, entry.expense)))
        ExpenseWarning.possibleDuplicate,
    };
  }

  static Money addedAmount(Expense candidate, {ExpenseEntry? original}) =>
      candidate.amount - (original?.expense.amount ?? Money.zero);

  static Set<ExpenseError> _dateErrors(
    CalendarDate? spentOn,
    MonthStatus status,
    CalendarDate today,
  ) {
    if (spentOn == null) {
      return status == MonthStatus.open ? {ExpenseError.dateMissing} : {};
    }
    return spentOn.isAfter(today) ? {ExpenseError.dateInFuture} : {};
  }

  static bool _looksLike(Expense candidate, Expense existing) {
    if (Names.key(candidate.name) != Names.key(existing.name)) return false;
    return switch ((candidate, existing)) {
      (final VariableExpense mine, final VariableExpense theirs) =>
        mine.amount == theirs.amount && mine.spentOn == theirs.spentOn,
      (VariableExpense(), _) || (_, VariableExpense()) => false,
      _ => true,
    };
  }
}
