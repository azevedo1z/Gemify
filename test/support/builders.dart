import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month.dart';
import 'package:offmoney/domain/month_closing.dart';
import 'package:offmoney/domain/reference_month.dart';

final defaultToday = CalendarDate(2026, 11, 7);
final defaultCreatedAt = DateTime.utc(2026, 11, 7, 12);

Money brl(String amount) {
  final negative = amount.startsWith('-');
  final digits = amount.replaceAll(RegExp('[^0-9,]'), '');
  final parts = digits.split(',');
  final cents =
      int.parse(parts.first) * 100 +
      (parts.length > 1 ? int.parse(parts.last.padRight(2, '0')) : 0);
  return Money(negative ? -cents : cents);
}

FixedExpense fixed(String name, String amount) =>
    FixedExpense(name: name, amount: brl(amount));

InstallmentExpense installment(
  String name,
  String amount,
  int current,
  int total,
) => InstallmentExpense(
  name: name,
  amount: brl(amount),
  current: current,
  total: total,
);

VariableExpense variable(String name, String amount, {CalendarDate? on}) =>
    VariableExpense(name: name, amount: brl(amount), spentOn: on);

ExpenseEntry entry(int id, Expense expense, {DateTime? createdAt}) =>
    ExpenseEntry(
      id: id,
      expense: expense,
      createdAt: createdAt ?? defaultCreatedAt,
      updatedAt: createdAt ?? defaultCreatedAt,
    );

List<ExpenseEntry> entries(List<Expense> expenses, {int firstId = 1}) => [
  for (var index = 0; index < expenses.length; index++)
    entry(firstId + index, expenses[index]),
];

Month openMonth({
  int id = 1,
  ReferenceMonth? reference,
  Money? income,
  List<ExpenseEntry> items = const [],
}) => Month(
  id: id,
  reference: reference ?? ReferenceMonth(2026, 11),
  status: MonthStatus.open,
  income: income,
  openedAt: defaultCreatedAt,
  closedAt: null,
  entries: items,
);

Month closedMonth({
  int id = 1,
  ReferenceMonth? reference,
  Money? income,
  List<ExpenseEntry> items = const [],
}) => Month(
  id: id,
  reference: reference ?? ReferenceMonth(2026, 10),
  status: MonthStatus.closed,
  income: income ?? brl('4.800,00'),
  openedAt: defaultCreatedAt,
  closedAt: defaultCreatedAt,
  entries: items,
);

ClosePlan planOf(CloseOutcome outcome) => switch (outcome) {
  ClosePlanned(:final plan) => plan,
  CloseRejected() => throw StateError('Expected a plan, got $outcome'),
};
