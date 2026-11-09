import 'package:offmoney/domain/month.dart';

enum TimelineError {
  noOpenMonth,
  severalOpenMonths,
  openMonthNotLatest,
  repeatedReference,
  closedMonthWithoutIncome,
  closedMonthWithoutCloseTime,
  openMonthWithCloseTime,
}

abstract final class MonthTimeline {
  static Set<TimelineError> errors(Iterable<Month> months) {
    final chronological = [...months]
      ..sort((a, b) => a.reference.compareTo(b.reference));
    final openCount = chronological.where((month) => month.isOpen).length;
    final closed = chronological.where((month) => !month.isOpen);
    return {
      if (openCount == 0) TimelineError.noOpenMonth,
      if (openCount > 1) TimelineError.severalOpenMonths,
      if (openCount == 1 && !chronological.last.isOpen)
        TimelineError.openMonthNotLatest,
      if (_hasRepeatedReference(chronological)) TimelineError.repeatedReference,
      if (closed.any((month) => month.income == null))
        TimelineError.closedMonthWithoutIncome,
      if (closed.any((month) => month.closedAt == null))
        TimelineError.closedMonthWithoutCloseTime,
      if (chronological.any((month) => month.isOpen && month.closedAt != null))
        TimelineError.openMonthWithCloseTime,
    };
  }

  static bool _hasRepeatedReference(List<Month> chronological) {
    for (var index = 1; index < chronological.length; index++) {
      if (chronological[index].reference ==
          chronological[index - 1].reference) {
        return true;
      }
    }
    return false;
  }
}
