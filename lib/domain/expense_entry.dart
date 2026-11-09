import 'package:meta/meta.dart';
import 'package:offmoney/domain/expense.dart';

@immutable
final class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.expense,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final Expense expense;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is ExpenseEntry &&
      other.id == id &&
      other.expense == expense &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, expense, createdAt, updatedAt);

  @override
  String toString() => 'ExpenseEntry(#$id, $expense)';
}
