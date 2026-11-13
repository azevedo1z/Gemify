import 'package:meta/meta.dart';
import 'package:offmoney/domain/calendar_date.dart';

@immutable
final class ReferenceMonth implements Comparable<ReferenceMonth> {
  ReferenceMonth(this.year, this.month) {
    if (!_isValid(year, month)) {
      throw ArgumentError('Invalid reference month: $year-$month');
    }
  }

  factory ReferenceMonth.containing(CalendarDate date) =>
      ReferenceMonth(date.year, date.month);

  factory ReferenceMonth.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      if (_isValid(year, month)) return ReferenceMonth(year, month);
    }
    throw FormatException('Expected an existing month as yyyy-MM', iso);
  }

  static const monthsInYear = 12;
  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})$');

  final int year;
  final int month;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  ReferenceMonth next() => plusMonths(1);

  ReferenceMonth plusMonths(int months) {
    final ordinal = _ordinal + months;
    return ReferenceMonth(ordinal ~/ monthsInYear, ordinal % monthsInYear + 1);
  }

  bool isAfter(ReferenceMonth other) => compareTo(other) > 0;

  int get _ordinal => year * monthsInYear + month - 1;

  static bool _isValid(int year, int month) =>
      month >= 1 &&
      month <= monthsInYear &&
      year >= CalendarDate.firstYear &&
      year <= CalendarDate.lastYear;

  @override
  int compareTo(ReferenceMonth other) => _ordinal.compareTo(other._ordinal);

  @override
  bool operator ==(Object other) =>
      other is ReferenceMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => iso;
}
