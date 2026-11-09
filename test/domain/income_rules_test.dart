import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/income_rules.dart';
import 'package:offmoney/domain/money.dart';

void main() {
  test('income goes from zero up to the cap', () {
    expect(IncomeRules.accepts(Money.zero), isTrue);
    expect(IncomeRules.accepts(Money.max), isTrue);
    expect(IncomeRules.accepts(const Money(-1)), isFalse);
    expect(IncomeRules.accepts(Money.max + const Money(1)), isFalse);
  });
}
