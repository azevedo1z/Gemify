import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/presentation/shared/money_input.dart';

TextEditingValue typed(String text) => TextEditingValue(text: text);

String afterTyping(String previous, String next) =>
    MoneyInputFormatter().formatEditUpdate(typed(previous), typed(next)).text;

String afterBackspace(String previous) => MoneyInputFormatter()
    .formatEditUpdate(
      TextEditingValue(
        text: previous,
        selection: TextSelection.collapsed(offset: previous.length),
      ),
      typed(previous.substring(0, previous.length - 1)),
    )
    .text;

String afterReplacingAll(String previous, String next) => MoneyInputFormatter()
    .formatEditUpdate(
      TextEditingValue(
        text: previous,
        selection: TextSelection(baseOffset: 0, extentOffset: previous.length),
      ),
      typed(next),
    )
    .text;

void main() {
  group('MoneyInputFormatter', () {
    test('fills from the right as digits are typed', () {
      var text = '';
      for (final digit in ['1', '2', '3', '4']) {
        text = afterTyping(text, '$text$digit');
      }

      expect(text, r'R$ 12,34');
    });

    test('deleting a digit shifts the value back', () {
      expect(afterTyping(r'R$ 12,34', r'R$ 12,3'), r'R$ 1,23');
    });

    test('backspace on every digit returns to empty, not to zero', () {
      final steps = [r'R$ 1,23'];
      for (var digit = 0; digit < 3; digit++) {
        steps.add(afterBackspace(steps.last));
      }

      expect(steps, [r'R$ 1,23', r'R$ 0,12', r'R$ 0,01', '']);
    });

    test(r'backspace on R$ 0,00 returns to empty', () {
      expect(afterBackspace(r'R$ 0,00'), isEmpty);
    });

    test('clearing the text returns to empty', () {
      expect(afterTyping(r'R$ 0,00', ''), isEmpty);
      expect(afterTyping(r'R$ 0,00', 'R'), isEmpty);
    });

    test(r'typing a zero gives R$ 0,00, distinct from empty', () {
      expect(afterTyping('', '0'), r'R$ 0,00');
      expect(afterTyping(r'R$ 0,00', r'R$ 0,000'), r'R$ 0,00');
      expect(afterReplacingAll(r'R$ 0,05', '0'), r'R$ 0,00');
    });

    test('typing something that is not a digit adds nothing', () {
      expect(afterTyping('', ','), isEmpty);
      expect(afterTyping(r'R$ 0,05', r'R$ 0,05,'), r'R$ 0,05');
    });

    test('ignores input above the cap', () {
      expect(
        afterTyping(r'R$ 999.999.999,99', r'R$ 999.999.999,999'),
        r'R$ 999.999.999,99',
      );
    });

    test('keeps the cursor at the end', () {
      final value = MoneyInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        typed('5'),
      );

      expect(value.selection.baseOffset, value.text.length);
    });
  });

  group('parseMoneyInput', () {
    test('reads the cents, or null when empty', () {
      expect(parseMoneyInput(r'R$ 1.234,50'), const Money(123450));
      expect(parseMoneyInput(r'R$ 0,00'), Money.zero);
      expect(parseMoneyInput(''), isNull);
    });

    test('rejects digits too long to be an amount', () {
      expect(parseMoneyInput('9' * 30), isNull);
    });
  });

  test('moneyInputText shows an amount, or nothing', () {
    expect(moneyInputText(const Money(700)), r'R$ 7,00');
    expect(moneyInputText(null), isEmpty);
  });
}
