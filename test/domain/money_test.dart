import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/money.dart';

void main() {
  group('Money', () {
    test('adds and subtracts exact cents', () {
      expect(const Money(10750) + const Money(30000), const Money(40750));
      expect(const Money(480000) - const Money(479999), const Money(1));
    });

    test('compares amounts', () {
      expect(const Money(1) > Money.zero, isTrue);
      expect(const Money(1) >= const Money(1), isTrue);
      expect(const Money(-1) < Money.zero, isTrue);
      expect(Money.zero <= Money.zero, isTrue);
      expect(const Money(5).compareTo(const Money(7)), isNegative);
    });

    test('tells its sign', () {
      expect(const Money(-1).isNegative, isTrue);
      expect(Money.zero.isNegative, isFalse);
      expect(Money.zero.isPositive, isFalse);
      expect(const Money(1).isPositive, isTrue);
    });

    test(r'caps at R$ 999.999.999,99', () {
      expect(Money.max.cents, 99999999999);
    });

    test('sums a list of amounts, zero when empty', () {
      expect(
        const [Money(100), Money(250), Money(-50)].total,
        const Money(300),
      );
      expect(const <Money>[].total, Money.zero);
    });

    test('sums a thousand items at the cap without overflow', () {
      final amounts = List.filled(1000, Money.max);

      expect(amounts.total, const Money(99999999999000));
    });

    test('is a value', () {
      expect({Money.zero + const Money(42), const Money(42)}, hasLength(1));
      expect(const Money(42).toString(), 'Money(42)');
    });
  });
}
