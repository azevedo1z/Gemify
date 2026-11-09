import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/month.dart';
import 'package:gemify/domain/month_timeline.dart';
import 'package:gemify/domain/reference_month.dart';

import '../support/builders.dart';

void main() {
  group('MonthTimeline.errors', () {
    test('accepts closed months followed by the open one, in any order', () {
      expect(
        MonthTimeline.errors([
          openMonth(id: 3, reference: ReferenceMonth(2026, 11)),
          closedMonth(reference: ReferenceMonth(2026, 9)),
          closedMonth(id: 2),
        ]),
        isEmpty,
      );
    });

    test('requires exactly one open month', () {
      expect(MonthTimeline.errors([closedMonth()]), {
        TimelineError.noOpenMonth,
      });
      expect(
        MonthTimeline.errors([
          openMonth(reference: ReferenceMonth(2026, 11)),
          openMonth(id: 2, reference: ReferenceMonth(2026, 12)),
        ]),
        {TimelineError.severalOpenMonths},
      );
    });

    test('requires the open month to be the latest', () {
      expect(
        MonthTimeline.errors([
          openMonth(reference: ReferenceMonth(2026, 9)),
          closedMonth(id: 2, reference: ReferenceMonth(2026, 10)),
        ]),
        {TimelineError.openMonthNotLatest},
      );
    });

    test('rejects repeated references', () {
      expect(
        MonthTimeline.errors([
          closedMonth(reference: ReferenceMonth(2026, 10)),
          closedMonth(id: 2, reference: ReferenceMonth(2026, 10)),
          openMonth(id: 3, reference: ReferenceMonth(2026, 11)),
        ]),
        {TimelineError.repeatedReference},
      );
    });

    test('requires income and close time in closed months only', () {
      final withoutIncome = Month(
        id: 1,
        reference: ReferenceMonth(2026, 10),
        status: MonthStatus.closed,
        income: null,
        openedAt: defaultCreatedAt,
        closedAt: null,
        entries: const [],
      );
      final openWithCloseTime = Month(
        id: 2,
        reference: ReferenceMonth(2026, 11),
        status: MonthStatus.open,
        income: null,
        openedAt: defaultCreatedAt,
        closedAt: defaultCreatedAt,
        entries: const [],
      );

      expect(MonthTimeline.errors([withoutIncome, openWithCloseTime]), {
        TimelineError.closedMonthWithoutIncome,
        TimelineError.closedMonthWithoutCloseTime,
        TimelineError.openMonthWithCloseTime,
      });
    });
  });
}
