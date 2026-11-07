import 'package:gemify/application/clock.dart';
import 'package:gemify/application/month_repository.dart';
import 'package:gemify/application/rejections.dart';
import 'package:gemify/domain/expense.dart';
import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/income_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_closing.dart';
import 'package:gemify/domain/month_timeline.dart';
import 'package:gemify/domain/names.dart';
import 'package:gemify/domain/reference_month.dart';

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

final class SaveExpense {
  const SaveExpense(this._repository, this._clock);

  final MonthRepository _repository;
  final Clock _clock;

  Future<void> call(Expense expense, {int? replacingId}) async {
    final cleaned = expense.withName(Names.clean(expense.name));
    final errors = ExpenseRules.errors(
      cleaned,
      status: MonthStatus.open,
      today: todayFrom(_clock),
    );
    if (errors.isNotEmpty) throw InvalidExpenseException(errors);
    if (replacingId == null) {
      await _repository.addExpense(cleaned);
    } else {
      await _repository.updateExpense(replacingId, cleaned);
    }
  }
}

final class DeleteExpense {
  const DeleteExpense(this._repository);

  final MonthRepository _repository;

  Future<void> call(int id) => _repository.deleteExpense(id);
}

final class ChangeOpenReference {
  const ChangeOpenReference(this._repository);

  final MonthRepository _repository;

  Future<void> call(ReferenceMonth reference) async {
    final latestClosed = await _repository.latestClosedReference();
    if (!MonthTimeline.acceptsOpenReference(
      reference,
      latestClosed: latestClosed,
    )) {
      throw InvalidReferenceException(reference);
    }
    await _repository.setOpenReference(reference);
  }
}

final class PrepareClose {
  const PrepareClose(this._clock);

  final Clock _clock;

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
