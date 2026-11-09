import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/domain/income_rules.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_summary.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/domain/reference_window.dart';

enum CloseError {
  monthNotOpen,
  incomeMissing,
  invalidExpenses,
  referenceNotAfterClosing,
  referenceTooFarAhead,
  newIncomeOutOfRange,
}

final class InstallmentStep {
  const InstallmentStep({required this.from, required this.to});

  final InstallmentExpense from;
  final InstallmentExpense to;
}

final class ClosePlan {
  const ClosePlan({
    required this.closingMonthId,
    required this.closingReference,
    required this.closingSummary,
    required this.newReference,
    required this.newIncome,
    required this.incomeKept,
    required this.keptFixed,
    required this.advancing,
    required this.finishing,
    required this.clearedVariables,
  });

  final int closingMonthId;
  final ReferenceMonth closingReference;
  final MonthSummary closingSummary;
  final ReferenceMonth newReference;
  final Money newIncome;
  final bool incomeKept;
  final List<ExpenseEntry> keptFixed;
  final List<InstallmentStep> advancing;
  final List<InstallmentExpense> finishing;
  final List<ExpenseEntry> clearedVariables;

  List<Expense> get newExpenses => [
    for (final entry in keptFixed) entry.expense,
    for (final step in advancing) step.to,
  ];
}

sealed class CloseOutcome {
  const CloseOutcome();
}

final class ClosePlanned extends CloseOutcome {
  const ClosePlanned(this.plan);

  final ClosePlan plan;

  @override
  String toString() =>
      'ClosePlanned(${plan.closingReference} -> ${plan.newReference})';
}

final class CloseRejected extends CloseOutcome {
  const CloseRejected({required this.errors, required this.invalidEntries});

  final Set<CloseError> errors;
  final Map<int, Set<ExpenseError>> invalidEntries;

  @override
  String toString() => 'CloseRejected($errors, $invalidEntries)';
}

abstract final class MonthClosing {
  static CloseOutcome plan({
    required Month month,
    required ReferenceMonth newReference,
    required Money? newIncome,
    required CalendarDate today,
  }) {
    final invalidEntries = _invalidEntries(month, today);
    final income = month.income;
    final window = ReferenceWindow.after(month.reference, today: today);
    final errors = {
      if (!month.isOpen) CloseError.monthNotOpen,
      if (income == null) CloseError.incomeMissing,
      if (invalidEntries.isNotEmpty) CloseError.invalidExpenses,
      if (window.first.isAfter(newReference))
        CloseError.referenceNotAfterClosing,
      if (newReference.isAfter(window.last)) CloseError.referenceTooFarAhead,
      if (newIncome != null && !IncomeRules.accepts(newIncome))
        CloseError.newIncomeOutOfRange,
    };
    if (errors.isNotEmpty || income == null) {
      return CloseRejected(errors: errors, invalidEntries: invalidEntries);
    }
    return ClosePlanned(
      _buildPlan(month, newReference, newIncome ?? income, newIncome == null),
    );
  }

  static Map<int, Set<ExpenseError>> _invalidEntries(
    Month month,
    CalendarDate today,
  ) {
    final invalid = <int, Set<ExpenseError>>{};
    for (final entry in month.entries) {
      final errors = ExpenseRules.errors(
        entry.expense,
        status: MonthStatus.open,
        today: today,
      );
      if (errors.isNotEmpty) invalid[entry.id] = errors;
    }
    return invalid;
  }

  static ClosePlan _buildPlan(
    Month month,
    ReferenceMonth newReference,
    Money newIncome,
    bool incomeKept,
  ) {
    final keptFixed = <ExpenseEntry>[];
    final advancing = <InstallmentStep>[];
    final finishing = <InstallmentExpense>[];
    final clearedVariables = <ExpenseEntry>[];
    for (final entry in month.entries) {
      switch (entry.expense) {
        case FixedExpense():
          keptFixed.add(entry);
        case final InstallmentExpense installment when installment.isLast:
          finishing.add(installment);
        case final InstallmentExpense installment:
          advancing.add(
            InstallmentStep(from: installment, to: installment.advanced()),
          );
        case VariableExpense():
          clearedVariables.add(entry);
      }
    }
    return ClosePlan(
      closingMonthId: month.id,
      closingReference: month.reference,
      closingSummary: month.summary,
      newReference: newReference,
      newIncome: newIncome,
      incomeKept: incomeKept,
      keptFixed: keptFixed,
      advancing: advancing,
      finishing: finishing,
      clearedVariables: clearedVariables,
    );
  }
}
