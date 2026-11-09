import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:offmoney/domain/expense_rules.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';
import 'package:offmoney/presentation/shared/labels.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('pt'));

  test('the installment minimum message comes from the rule', () {
    expect(
      expenseErrorMessage(ExpenseError.installmentTotalBelowMinimum, l10n),
      'Mínimo de ${ExpenseRules.minimumInstallments} parcelas',
    );
  });
}
