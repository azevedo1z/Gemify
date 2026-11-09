import 'package:flutter_test/flutter_test.dart';
import 'package:gemify/domain/calendar_date.dart';
import 'package:gemify/domain/reference_month.dart';
import 'package:gemify/domain/reference_window.dart';

void main() {
  final today = CalendarDate(2026, 11, 7);

  group('ReferenceWindow.after', () {
    test(
      'spans a year back to three months ahead while nothing was closed',
      () {
        final window = ReferenceWindow.after(null, today: today);

        expect(window.first, ReferenceMonth(2025, 11));
        expect(window.last, ReferenceMonth(2027, 2));
      },
    );

    test('starts right after the latest closed month', () {
      final window = ReferenceWindow.after(
        ReferenceMonth(2026, 10),
        today: today,
      );

      expect(window.first, ReferenceMonth(2026, 11));
      expect(window.last, ReferenceMonth(2027, 2));
    });

    test('still offers the next month when the latest close is far ahead', () {
      final window = ReferenceWindow.after(
        ReferenceMonth(2027, 5),
        today: today,
      );

      expect(window.first, ReferenceMonth(2027, 6));
      expect(window.last, ReferenceMonth(2027, 6));
    });
  });

  test('contains both ends and nothing outside them', () {
    final window = ReferenceWindow.after(
      ReferenceMonth(2026, 10),
      today: today,
    );

    expect(window.contains(ReferenceMonth(2026, 10)), isFalse);
    expect(window.contains(ReferenceMonth(2026, 11)), isTrue);
    expect(window.contains(ReferenceMonth(2027, 2)), isTrue);
    expect(window.contains(ReferenceMonth(2027, 3)), isFalse);
  });
}
