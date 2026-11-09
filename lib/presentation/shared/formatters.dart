import 'package:offmoney/domain/calendar_date.dart';
import 'package:offmoney/domain/money.dart';
import 'package:offmoney/domain/month_summary.dart';
import 'package:offmoney/domain/reference_month.dart';
import 'package:offmoney/presentation/l10n/generated/app_localizations.dart';

const _centsPerReal = 100;
const _thousandsGroup = 3;

String formatAmount(Money amount) {
  final cents = amount.cents.abs();
  final reais = (cents ~/ _centsPerReal).toString();
  final rest = (cents % _centsPerReal).toString().padLeft(2, '0');
  final sign = amount.isNegative ? '-' : '';
  return '$sign${_groupThousands(reais)},$rest';
}

String formatMoney(Money amount) {
  final sign = amount.isNegative ? '-' : '';
  return '${sign}R\$ ${formatAmount(Money(amount.cents.abs()))}';
}

String formatDate(CalendarDate date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

String formatReference(ReferenceMonth reference, AppLocalizations l10n) =>
    '${_monthAbbreviation(reference.month, l10n)}/${reference.year}';

String formatAuditLine(MonthSummary summary) {
  final income = summary.income;
  final balance = summary.balance;
  if (income == null || balance == null) return '';
  return '${formatAmount(income)} - (${formatAmount(summary.fixedTotal)} + '
      '${formatAmount(summary.installmentTotal)} + '
      '${formatAmount(summary.variableTotal)}) = ${formatAmount(balance)}';
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    if (index > 0 && remaining % _thousandsGroup == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}

String _monthAbbreviation(int month, AppLocalizations l10n) => switch (month) {
  1 => l10n.monthJan,
  2 => l10n.monthFeb,
  3 => l10n.monthMar,
  4 => l10n.monthApr,
  5 => l10n.monthMay,
  6 => l10n.monthJun,
  7 => l10n.monthJul,
  8 => l10n.monthAug,
  9 => l10n.monthSep,
  10 => l10n.monthOct,
  11 => l10n.monthNov,
  _ => l10n.monthDec,
};
