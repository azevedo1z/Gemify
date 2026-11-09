import 'package:offmoney/domain/calendar_date.dart';

typedef Clock = DateTime Function();

DateTime systemClock() => DateTime.now().toUtc();

CalendarDate todayFrom(Clock clock) => CalendarDate.of(clock().toLocal());
