import 'package:meta/meta.dart';
import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/reference_month.dart';

@immutable
final class ReferenceWindow {
  factory ReferenceWindow.after(
    ReferenceMonth? latestClosed, {
    required CalendarDate today,
  }) {
    final current = ReferenceMonth.containing(today);
    final first = latestClosed?.next() ?? current.plusMonths(-monthsBack);
    final ahead = current.plusMonths(monthsAhead);
    return ReferenceWindow._(first, ahead.isAfter(first) ? ahead : first);
  }

  const ReferenceWindow._(this.first, this.last);

  static const monthsBack = 12;
  static const monthsAhead = 3;

  final ReferenceMonth first;
  final ReferenceMonth last;

  bool contains(ReferenceMonth reference) =>
      !first.isAfter(reference) && !reference.isAfter(last);
}
