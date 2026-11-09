import 'package:flutter/services.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/presentation/shared/formatters.dart';

final _nonDigits = RegExp(r'\D');

Money? parseMoneyInput(String text) {
  final digits = text.replaceAll(_nonDigits, '');
  if (digits.isEmpty) return null;
  final cents = int.tryParse(digits);
  return cents == null ? null : Money(cents);
}

String moneyInputText(Money? amount) =>
    amount == null ? '' : formatMoney(amount);

final class MoneyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return TextEditingValue.empty;
    final cents = int.tryParse(digits);
    if (cents == null || cents > Money.max.cents) return oldValue;
    if (cents == 0 && !_inserted(oldValue, newValue)) {
      return TextEditingValue.empty;
    }
    final text = formatMoney(Money(cents));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static bool _inserted(TextEditingValue oldValue, TextEditingValue newValue) {
    final selection = oldValue.selection;
    final replaced = selection.isValid ? selection.end - selection.start : 0;
    return newValue.text.length > oldValue.text.length - replaced;
  }
}
