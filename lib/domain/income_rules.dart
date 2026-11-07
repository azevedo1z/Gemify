import 'package:gemify/domain/money.dart';

abstract final class IncomeRules {
  static bool accepts(Money income) =>
      !income.isNegative && income <= Money.max;
}
