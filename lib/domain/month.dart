import 'package:gemify/domain/expense_entry.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/month_summary.dart';
import 'package:gemify/domain/reference_month.dart';

enum MonthStatus { open, closed }

final class Month {
  const Month({
    required this.id,
    required this.reference,
    required this.status,
    required this.income,
    required this.openedAt,
    required this.closedAt,
    required this.entries,
  });

  final int id;
  final ReferenceMonth reference;
  final MonthStatus status;
  final Money? income;
  final DateTime openedAt;
  final DateTime? closedAt;
  final List<ExpenseEntry> entries;

  bool get isOpen => status == MonthStatus.open;

  MonthSummary get summary => MonthSummary.of(
    income: income,
    expenses: [for (final entry in entries) entry.expense],
  );
}
