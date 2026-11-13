import 'package:meta/meta.dart';

@immutable
final class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    if (!_exists(year, month, day)) {
      throw ArgumentError('Invalid date: $year-$month-$day');
    }
  }

  factory CalendarDate.of(DateTime moment) =>
      CalendarDate(moment.year, moment.month, moment.day);

  factory CalendarDate.parse(String iso) {
    final match = _isoPattern.firstMatch(iso);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      if (_exists(year, month, day)) return CalendarDate(year, month, day);
    }
    throw FormatException('Expected an existing date as yyyy-MM-dd', iso);
  }

  static const firstYear = 1;
  static const lastYear = 9999;
  static final _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  String get iso =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  static bool _exists(int year, int month, int day) {
    if (year < firstYear || year > lastYear) return false;
    final probe = DateTime.utc(year, month, day);
    return probe.year == year && probe.month == month && probe.day == day;
  }

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => iso;
}
