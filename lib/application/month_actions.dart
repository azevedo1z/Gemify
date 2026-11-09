import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_repository.dart';
import 'package:gemify/application/rejections.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/income_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/domain/reference_window.dart';

final class StartMonth {
  const StartMonth(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  Future<void> call() => _repository.ensureOpenMonth(
    ReferenceMonth.containing(todayFrom(_clock)),
  );
}

final class SetIncome {
  const SetIncome(this._repository);

  final MonthRepository _repository;

  Future<void> call(Money income) async {
    if (!IncomeRules.accepts(income)) throw InvalidIncomeException(income);
    await _repository.setIncome(income);
  }
}

final class ExpenseCheck {
  const ExpenseCheck({
    required this.expense,
    this.errors = const {},
    this.warnings = const {},
    this.addedAmount = Money.zero,
    this.balance,
  });

  final Expense expense;
  final Set<ExpenseError> errors;
  final Set<ExpenseWarning> warnings;
  final Money addedAmount;
  final Money? balance;

  bool get isValid => errors.isEmpty;
}

final class CheckExpense {
  const CheckExpense(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  Future<ExpenseCheck> call(Expense expense, {ExpenseEntry? original}) async {
    final cleaned = ExpenseRules.cleaned(expense);
    final errors = _openMonthErrors(cleaned, _clock);
    if (errors.isNotEmpty) {
      return ExpenseCheck(expense: cleaned, errors: errors);
    }
    final month = await _repository.openMonth();
    return ExpenseCheck(
      expense: cleaned,
      warnings: ExpenseRules.warnings(
        cleaned,
        month: month,
        original: original,
      ),
      addedAmount: ExpenseRules.addedAmount(cleaned, original: original),
      balance: month.summary.balance,
    );
  }
}

final class SaveExpense {
  const SaveExpense(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  Future<void> call(Expense expense, {int? replacingId}) async {
    final cleaned = ExpenseRules.cleaned(expense);
    final errors = _openMonthErrors(cleaned, _clock);
    if (errors.isNotEmpty) throw InvalidExpenseException(errors);
    if (replacingId == null) {
      await _repository.addExpense(cleaned);
    } else {
      await _repository.updateExpense(replacingId, cleaned);
    }
  }
}

Set<ExpenseError> _openMonthErrors(Expense expense, Clock clock) =>
    ExpenseRules.errors(
      expense,
      status: MonthStatus.open,
      today: todayFrom(clock),
    );

final class DeleteExpense {
  const DeleteExpense(this._repository);

  final MonthRepository _repository;

  Future<void> call(int id) => _repository.deleteExpense(id);
}

final class ChangeOpenReference {
  const ChangeOpenReference(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  Future<ReferenceWindow> window() async => ReferenceWindow.after(
    await _repository.latestClosedReference(),
    today: todayFrom(_clock),
  );

  Future<void> call(ReferenceMonth reference) async {
    if (!(await window()).contains(reference)) {
      throw InvalidReferenceException(reference);
    }
    await _repository.setOpenReference(reference);
  }
}

final class PrepareClose {
  const PrepareClose(this._clock);

  final Clock _clock;

  ReferenceWindow window(Month month) =>
      ReferenceWindow.after(month.reference, today: todayFrom(_clock));

  CloseOutcome call(
    Month month, {
    ReferenceMonth? newReference,
    Money? newIncome,
  }) => MonthClosing.plan(
    month: month,
    newReference: newReference ?? month.reference.next(),
    newIncome: newIncome,
    today: todayFrom(_clock),
  );
}

final class ConfirmClose {
  const ConfirmClose(this._repository);

  final MonthRepository _repository;

  Future<void> call(ClosePlan plan) => _repository.applyClose(plan);
}
