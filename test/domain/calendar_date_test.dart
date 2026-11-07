import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';

void main() {
  group('CalendarDate', () {
    test('rejects dates that do not exist', () {
      expect(() => CalendarDate(2026, 2, 30), throwsArgumentError);
      expect(() => CalendarDate(2026, 13, 1), throwsArgumentError);
      expect(() => CalendarDate(0, 1, 1), throwsArgumentError);
    });

    test('takes the local date of a moment', () {
      expect(
        CalendarDate.of(DateTime(2026, 11, 7, 23, 59)),
        CalendarDate(2026, 11, 7),
      );
    });

    test('orders by year, month and day', () {
      final dates = [
        CalendarDate(2026, 11, 7),
        CalendarDate(2025, 12, 31),
        CalendarDate(2026, 1, 15),
      ]..sort();

      expect(dates, [
        CalendarDate(2025, 12, 31),
        CalendarDate(2026, 1, 15),
        CalendarDate(2026, 11, 7),
      ]);
      expect(
        CalendarDate(2026, 11, 8).isAfter(CalendarDate(2026, 11, 7)),
        isTrue,
      );
      expect(
        CalendarDate(2026, 11, 7).isAfter(CalendarDate(2026, 11, 7)),
        isFalse,
      );
    });

    test('reads and writes ISO dates', () {
      expect(CalendarDate.parse('2026-03-09'), CalendarDate(2026, 3, 9));
      expect(CalendarDate(2026, 3, 9).iso, '2026-03-09');
      expect(CalendarDate(2026, 3, 9).toString(), '2026-03-09');
    });

    test('rejects malformed ISO dates', () {
      expect(() => CalendarDate.parse('2026-3-9'), throwsFormatException);
      expect(() => CalendarDate.parse('09/03/2026'), throwsFormatException);
      expect(() => CalendarDate.parse('2026-02-30'), throwsFormatException);
    });

    test('is a value', () {
      expect({
        CalendarDate(2026, 1, 1),
        CalendarDate(2026, 1, 1),
      }, hasLength(1));
    });
  });
}
