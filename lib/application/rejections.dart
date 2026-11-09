import 'package:gemify/domain/expense_rules.dart';
import 'package:gemify/domain/money.dart';
import 'package:gemify/domain/reference_month.dart';

final class InvalidExpenseException implements Exception {
  const InvalidExpenseException(this.errors);

  final Set<ExpenseError> errors;

  @override
  String toString() => 'Invalid expense: $errors';
}

final class InvalidIncomeException implements Exception {
  const InvalidIncomeException(this.income);

  final Money income;

  @override
  String toString() => 'Invalid income: $income';
}

final class InvalidReferenceException implements Exception {
  const InvalidReferenceException(this.reference);

  final ReferenceMonth reference;

  @override
  String toString() => 'Reference $reference is outside the allowed window';
}
