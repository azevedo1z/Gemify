import 'package:meta/meta.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/money.dart';

@immutable
final class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.fixedTotal,
    required this.installmentTotal,
    required this.variableTotal,
  });

  factory MonthSummary.of({
    required Money? income,
    required Iterable<Expense> expenses,
  }) {
    var fixedTotal = Money.zero;
    var installmentTotal = Money.zero;
    var variableTotal = Money.zero;
    for (final expense in expenses) {
      switch (expense) {
        case FixedExpense():
          fixedTotal += expense.amount;
        case InstallmentExpense():
          installmentTotal += expense.amount;
        case VariableExpense():
          variableTotal += expense.amount;
      }
    }
    return MonthSummary(
      income: income,
      fixedTotal: fixedTotal,
      installmentTotal: installmentTotal,
      variableTotal: variableTotal,
    );
  }

  final Money? income;
  final Money fixedTotal;
  final Money installmentTotal;
  final Money variableTotal;

  Money get totalExpenses => fixedTotal + installmentTotal + variableTotal;

  Money? get balance {
    final income = this.income;
    return income == null ? null : income - totalExpenses;
  }

  @override
  bool operator ==(Object other) =>
      other is MonthSummary &&
      other.income == income &&
      other.fixedTotal == fixedTotal &&
      other.installmentTotal == installmentTotal &&
      other.variableTotal == variableTotal;

  @override
  int get hashCode =>
      Object.hash(income, fixedTotal, installmentTotal, variableTotal);
}
