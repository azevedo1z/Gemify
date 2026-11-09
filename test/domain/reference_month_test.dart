import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/reference_month.dart';

void main() {
  group('ReferenceMonth', () {
    test('rejects months outside 1 to 12 and years outside 1 to 9999', () {
      expect(() => ReferenceMonth(2026, 0), throwsArgumentError);
      expect(() => ReferenceMonth(2026, 13), throwsArgumentError);
      expect(() => ReferenceMonth(0, 1), throwsArgumentError);
      expect(() => ReferenceMonth(10000, 1), throwsArgumentError);
    });

    test('moves to the next month, turning the year after December', () {
      expect(ReferenceMonth(2026, 11).next(), ReferenceMonth(2026, 12));
      expect(ReferenceMonth(2026, 12).next(), ReferenceMonth(2027, 1));
    });

    test('moves by any number of months across years', () {
      expect(ReferenceMonth(2026, 11).plusMonths(3), ReferenceMonth(2027, 2));
      expect(
        ReferenceMonth(2026, 11).plusMonths(-12),
        ReferenceMonth(2025, 11),
      );
      expect(ReferenceMonth(2026, 1).plusMonths(-1), ReferenceMonth(2025, 12));
      expect(ReferenceMonth(2026, 5).plusMonths(0), ReferenceMonth(2026, 5));
    });

    test('is the month that contains a date', () {
      expect(
        ReferenceMonth.containing(CalendarDate(2026, 11, 7)),
        ReferenceMonth(2026, 11),
      );
    });

    test('orders chronologically', () {
      expect(ReferenceMonth(2027, 1).isAfter(ReferenceMonth(2026, 12)), isTrue);
      expect(
        ReferenceMonth(2026, 12).isAfter(ReferenceMonth(2026, 12)),
        isFalse,
      );
      expect(
        ReferenceMonth(2026, 1).compareTo(ReferenceMonth(2025, 12)),
        isPositive,
      );
    });

    test('reads and writes ISO year-month', () {
      expect(ReferenceMonth.parse('2026-03'), ReferenceMonth(2026, 3));
      expect(ReferenceMonth(2026, 3).iso, '2026-03');
      expect(ReferenceMonth(2026, 3).toString(), '2026-03');
      expect(() => ReferenceMonth.parse('2026-3'), throwsFormatException);
      expect(() => ReferenceMonth.parse('2026-13'), throwsFormatException);
    });

    test('is a value', () {
      expect({ReferenceMonth(2026, 1), ReferenceMonth(2026, 1)}, hasLength(1));
    });
  });
}
