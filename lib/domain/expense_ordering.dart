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
    return switch ((a.expense, b.expense)) {
      (
        VariableExpense(spentOn: final first),
        VariableExpense(spentOn: final second),
      ) =>
        _newestFirst(a, b, first, second),
      _ => _alphabetical(a, b),
    };
  }

  static int _alphabetical(ExpenseEntry a, ExpenseEntry b) {
    final byName = Names.key(a.expense.name).compareTo(
      Names.key(b.expense.name),
    );
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }

  static int _newestFirst(
    ExpenseEntry a,
    ExpenseEntry b,
    CalendarDate? first,
    CalendarDate? second,
  ) {
    final byDate = _datesNewestFirst(first, second);
    if (byDate != 0) return byDate;
    final byCreation = b.createdAt.compareTo(a.createdAt);
    return byCreation != 0 ? byCreation : b.id.compareTo(a.id);
  }

  static int _datesNewestFirst(CalendarDate? first, CalendarDate? second) {
    if (first == second) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return second.compareTo(first);
  }
}
