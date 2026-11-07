import 'package:gemify/domain/expense.dart';

abstract final class ExpenseJson {
  static const category = 'category';
  static const name = 'name';
  static const amountCents = 'amountCents';
  static const currentInstallment = 'currentInstallment';
  static const totalInstallments = 'totalInstallments';
  static const spentOn = 'spentOn';

  static Map<String, Object?> encode(Expense expense) => {
    category: expense.category.name,
    name: expense.name,
    amountCents: expense.amount.cents,
    ...switch (expense) {
      FixedExpense() => const <String, Object?>{},
      InstallmentExpense(:final current, :final total) => {
        currentInstallment: current,
        totalInstallments: total,
      },
      VariableExpense(spentOn: final date) => {spentOn: date?.iso},
    },
  };
}
