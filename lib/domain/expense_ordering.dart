import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/expense.dart';
import 'package:offmoney/domain/expense_entry.dart';
import 'package:offmoney/domain/names.dart';

abstract final class ExpenseOrdering {
  static List<ExpenseEntry> sorted(Iterable<ExpenseEntry> entries) =>
      [...entries]..sort(compare);

  static int compare(ExpenseEntry a, ExpenseEntry b) {
    final byCategory = a.expense.category.index.compareTo(
      b.expense.category.index,
    );
    if (byCategory != 0) return byCategory;
    final withinCategory = switch ((a.expense, b.expense)) {
      (
        InstallmentExpense(remaining: final first),
        InstallmentExpense(remaining: final second),
      ) =>
        first.compareTo(second),
      (
        VariableExpense(spentOn: final first),
        VariableExpense(spentOn: final second),
      ) =>
        _oldestFirst(first, second),
      _ => Names.key(a.expense.name).compareTo(Names.key(b.expense.name)),
    };
    return withinCategory != 0 ? withinCategory : a.id.compareTo(b.id);
  }

  static int _oldestFirst(CalendarDate? first, CalendarDate? second) {
    if (first == second) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }
}
